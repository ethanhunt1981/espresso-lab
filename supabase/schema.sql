-- =====================================================================
-- Espresso Lab — Community-Kaffee-Bibliothek
-- SQL-Schema v2.1 (gehärtet, Security-Hardening nach LLM Security Council
-- + Supabase Security Advisor)
--
-- Fixes gegenüber v1:
--   * RLS ZWINGEND aktiviert (Critical Fix #1)  — v1 verließ sich auf
--     die (falsche) Annahme, das sei bei SQL-Erstellung automatisch so.
--   * Harte Längen-/Wertebereichs-Constraints auf ALLEN Spalten
--     inkl. `origin` & `process` (Fix #2 „Generated-Column-Bomb“)
--     und Ausschluss von Postgres-'NaN' + Wertebereichen (Fix #4).
--   * Trigram-Index (pg_trgm) passend zur ILIKE-Suche statt des
--     nie verwendeten to_tsvector-GIN (Fix #5, Such-DoS).
--   * Datenbank-Trigger als Rate-Limit gegen Bot-Flooding (Fix #3).
--   * Expliziter Entzug von UPDATE/DELETE/TRUNCATE für anon/authenticated
--     (Defense in Depth, zusätzlich zu RLS).
--
-- Fixes in v2.1 (Supabase Security Advisor):
--   * pg_trgm lebt im 'extensions'-Schema statt 'public' (Best Practice)
--   * check_coffee_rate_limit(): EXECUTE für public/anon/authenticated
--     entzogen (Funktion ist nur als interner Trigger aktiv)
--   * search_path der SECURITY DEFINER-Funktion fixiert auf
--     public, extensions
--   * rls_auto_enable() (falls vorhanden) analog gesperrt
--
-- Ausführen: Supabase Dashboard → SQL Editor → New Query → einfügen → Run
-- Idempotent: kann sowohl auf frischem Projekt als auch zur Nachrüstung
-- einer bestehenden Tabelle ausgeführt werden.
-- =====================================================================

-- 1. Erweiterung für schnelle ILIKE '%...%'-Suche (Fix #5)
--    Best Practice Supabase: Extensions NACH MÖGLICHKEIT ins 'extensions'-Schema
create schema if not exists extensions;
create extension if not exists pg_trgm with schema extensions;

-- Falls pg_trgm bereits aus einer älteren Version im 'public'-Schema
-- installiert ist: sauber nach 'extensions' umziehen (OID-Referenzen
-- des Trigram-Index bleiben dabei erhalten, kein Rebuild nötig).
do $$
begin
    if exists (
        select 1
        from pg_extension e
        join pg_namespace n on n.oid = e.extnamespace
        where e.extname = 'pg_trgm' and n.nspname = 'public'
    ) then
        alter extension pg_trgm set schema extensions;
    end if;
end $$;

-- 2. Tabelle für Kaffee-Profile (jede Zeile = ein Shots-Eintrag mit
--    Bohnen-Daten, verwendeten Einstellungen und erzieltem Ergebnis)
create table if not exists public.coffees (
    id            uuid primary key default gen_random_uuid(),

    -- Bohne / Marke
    brand         text not null,              -- Marke oder Röster
    coffee_name   text not null,              -- Name des Kaffees
    origin        text,                       -- Herkunft, z.B. "Äthiopien, Yirgacheffe"
    roast_level   text not null default 'mittel'
                  check (roast_level in ('hell', 'mittel-hell', 'mittel', 'mittel-dunkel', 'dunkel')),
    process       text,                       -- Aufbereitung, z.B. "gewaschen" / "natural"

    -- Einstellungen des Bezugs
    dose          numeric not null default 18.0,   -- g
    grind_microns integer not null default 250,    -- µm
    temp_c        numeric not null default 93.0,   -- °C
    pressure_bar  numeric not null default 9.0,    -- bar
    shot_time_s   integer not null default 28,     -- s

    -- Ergebnis des Shots
    ey_percent    numeric,                    -- Extraction Yield %
    tds_percent   numeric,                    -- Total Dissolved Solids %
    acidity       numeric,                    -- 0-10
    sweetness     numeric,                    -- 0-10
    bitterness    numeric,                    -- 0-10

    -- Freitext & Meta
    notes         text,                       -- Cupping-Notizen
    author_name   text,                       -- Spitzname des Contributors (optional)
    created_at    timestamptz not null default now(),

    -- Komfort: automatisch gepflegte Such-Spalte über Marke + Name + Herkunft + Notizen
    search_text   text generated always as (
                      lower(coalesce(brand, '') || ' ' || coalesce(coffee_name, '') || ' ' ||
                            coalesce(origin, '') || ' ' || coalesce(notes, ''))
                  ) stored
);

-- Komfort-Spalte nachrüsten, falls die Tabelle noch aus v1 stammt (ohne search_text)
alter table public.coffees add column if not exists search_text text
    generated always as (
        lower(coalesce(brand, '') || ' ' || coalesce(coffee_name, '') || ' ' ||
              coalesce(origin, '') || ' ' || coalesce(notes, ''))
    ) stored;

-- =====================================================================
-- 3. ROW LEVEL SECURITY ZWINGEND AKTIVIEREN (Fix #1, KRITISCH)
--    Ohne diese Zeile werden sämtliche Policies unten ignoriert!
-- =====================================================================
alter table public.coffees enable row level security;

-- Defense in Depth: UPDATE/DELETE/TRUNCATE entziehen (auch ohne Policies
-- unwirksam machen). Moderation läuft ausschließlich über die Supabase-
-- Build-in-Rollen (Dashboard/Table Editor).
revoke update, delete, truncate on table public.coffees from anon;
revoke update, delete, truncate on table public.coffees from authenticated;

-- =====================================================================
-- 4. Harte Constraints auf allen Spalten (Fix #2 & #4)
--    Betrifft auch Direkt-API-POSTs, die das Frontend umgehen.
-- =====================================================================
alter table public.coffees
    drop constraint if exists coffees_limits_check,
    add constraint coffees_limits_check check (
        -- Textlängen (auch für origin und process!)
        length(trim(brand)) between 2 and 80
        and length(trim(coffee_name)) between 2 and 120
        and char_length(coalesce(origin, '')) <= 120
        and char_length(coalesce(process, '')) <= 60
        and char_length(coalesce(notes, '')) <= 500
        and char_length(coalesce(author_name, '')) <= 40
        -- Numerische Bereiche + Ausschluss von Postgres-'NaN'
        and dose != 'NaN'::numeric and dose between 5.0 and 30.0
        and grind_microns between 150 and 400
        and temp_c != 'NaN'::numeric and temp_c between 86.0 and 98.0
        and pressure_bar != 'NaN'::numeric and pressure_bar between 3.0 and 12.0
        and shot_time_s between 15 and 45
        and (ey_percent  is null or (ey_percent  != 'NaN'::numeric and ey_percent  between 5.0 and 35.0))
        and (tds_percent is null or (tds_percent != 'NaN'::numeric and tds_percent between 1.0 and 25.0))
        and (acidity     is null or (acidity     != 'NaN'::numeric and acidity     between 0.0 and 10.0))
        and (sweetness   is null or (sweetness   != 'NaN'::numeric and sweetness   between 0.0 and 10.0))
        and (bitterness  is null or (bitterness  != 'NaN'::numeric and bitterness  between 0.0 and 10.0))
    );

-- =====================================================================
-- 5. Indizes
--    Trigram-Index passt zur ILIKE-Abfrage im Frontend; der v1-
--    to_tsvector-Index wurde bei ILIKE implizit ignoriert (Fix #5).
-- =====================================================================
drop index if exists public.coffees_search_idx;
drop index if exists public.coffees_search_trgm_idx;
create index coffees_search_trgm_idx
    on public.coffees using gin (search_text extensions.gin_trgm_ops);
create index if not exists coffees_created_idx on public.coffees (created_at desc);
create index if not exists coffees_brand_idx   on public.coffees (lower(brand));

-- =====================================================================
-- 6. Policies (RLS-Regeln) — anonymes Lesen + Anlegen, sonst nichts
-- =====================================================================

-- a) Jeder darf lesen (auch anonyme Besucher der Website)
drop policy if exists "Jeder darf Kaffees lesen" on public.coffees;
create policy "Jeder darf Kaffees lesen"
    on public.coffees for select
    to anon, authenticated
    using (true);

-- b) Jeder darf einen Eintrag anlegen (Kaffee hinterlegen), ohne Login
--    (Längen-/Plausibilitäts-Checks zusätzlich zur Table-Constraint)
drop policy if exists "Jeder darf einen Kaffee anlegen" on public.coffees;
create policy "Jeder darf einen Kaffee anlegen"
    on public.coffees for insert
    to anon, authenticated
    with check (
        length(trim(brand)) >= 2
        and length(trim(coffee_name)) >= 2
        and char_length(brand)  <= 80
        and char_length(coffee_name) <= 120
        and char_length(coalesce(notes, '')) <= 500
        and char_length(coalesce(author_name, '')) <= 40
    );

-- c) Bewusst KEIN Update-/Delete-Zugriff für anonyme Nutzer: niemand kann
--    fremde Einträge verändern oder löschen. Moderation erfolgt über dein
--    Supabase-Dashboard (Table Editor), da du dort als Projekt-Inhaber
--    (Rolle postgres) die Policies umgehst.

-- =====================================================================
-- 7. Datenbank-seitiges Rate-Limiting gegen Bot-Flooding (Fix #3)
--    Max. 5 neue Einträge pro Minute (global). Verstöße brechen den
--    INSERT mit Fehler ab — das Frontend fängt das ab und speichert
--    lokal weiter, bis wieder Platz ist.
-- =====================================================================
create or replace function public.check_coffee_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    recent_count integer;
begin
    select count(*) into recent_count
    from public.coffees
    where created_at > (now() - interval '1 minute');

    if recent_count >= 5 then
        raise exception 'Rate limit exceeded: Bitte warte einen Moment vor dem nächsten Eintrag.'
            using errcode = 'P0001';
    end if;
    return new;
end;
$$;

drop trigger if exists enforce_coffee_rate_limit on public.coffees;
create trigger enforce_coffee_rate_limit
    before insert on public.coffees
    for each row execute function public.check_coffee_rate_limit();

-- SECURITY DEFINER-Funktion härten (Supabase Security Advisor):
-- EXECUTE komplett entziehen — die Funktion läuft nur intern als Trigger.
revoke execute on function public.check_coffee_rate_limit() from public;
revoke execute on function public.check_coffee_rate_limit() from anon;
revoke execute on function public.check_coffee_rate_limit() from authenticated;
alter function public.check_coffee_rate_limit() set search_path = public, extensions;

-- rls_auto_enable() (falls von Supabase angelegt) analog sperren
do $$
begin
    if exists (
        select 1 from pg_proc p
        join pg_namespace n on p.pronamespace = n.oid
        where n.nspname = 'public' and p.proname = 'rls_auto_enable'
    ) then
        execute 'revoke execute on function public.rls_auto_enable() from public, anon, authenticated;';
        execute 'alter function public.rls_auto_enable() set search_path = public, extensions;';
    end if;
end $$;

-- =====================================================================
-- 8. Bewertungen (Phase 5.3): 👍-Stimmen pro Kaffee — v2.2
-- =====================================================================
create table if not exists public.coffee_votes (
    id            uuid primary key default gen_random_uuid(),
    coffee_id     uuid not null references public.coffees(id) on delete cascade,
    voter_token   text not null,
    created_at    timestamptz not null default now(),
    unique (coffee_id, voter_token)
);

create index if not exists coffee_votes_coffee_idx on public.coffee_votes (coffee_id);

alter table public.coffee_votes enable row level security;
revoke update, delete, truncate on table public.coffee_votes from anon;
revoke update, delete, truncate on table public.coffee_votes from authenticated;

drop policy if exists "Jeder darf Bewertungen lesen" on public.coffee_votes;
create policy "Jeder darf Bewertungen lesen"
    on public.coffee_votes for select
    to anon, authenticated
    using (true);

drop policy if exists "Jeder darf eine Bewertung abgeben" on public.coffee_votes;
create policy "Jeder darf eine Bewertung abgeben"
    on public.coffee_votes for insert
    to anon, authenticated
    with check (
        coffee_id is not null
        and char_length(trim(voter_token)) between 8 and 64
    );

create or replace function public.check_vote_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
    recent_count integer;
begin
    select count(*) into recent_count
    from public.coffee_votes
    where created_at > (now() - interval '1 minute');

    if recent_count >= 20 then
        raise exception 'Rate limit exceeded: Bitte warte einen Moment, bevor du weiter bewertest.'
            using errcode = 'P0001';
    end if;
    return new;
end;
$$;

drop trigger if exists enforce_vote_rate_limit on public.coffee_votes;
create trigger enforce_vote_rate_limit
    before insert on public.coffee_votes
    for each row execute function public.check_vote_rate_limit();

revoke execute on function public.check_vote_rate_limit() from public;
revoke execute on function public.check_vote_rate_limit() from anon;
revoke execute on function public.check_vote_rate_limit() from authenticated;

-- =====================================================================
-- Nach dem Ausführen verifizieren:
--   → Dashboard → Database → Tables → coffees → Badge „RLS Enabled"
--   → Extensions (pg_trgm) liegen im `extensions`-Schema, nicht in `public`
--   → Security Advisor (Dashboard ⇢ Advisors): 0 Errors, 0 Warnings
--   → Test: mit dem anon key per REST einen INSERT mit 10MB-Text
--     oder DELETE-Versuch senden — beides muss fehlschlagen.
-- =====================================================================
