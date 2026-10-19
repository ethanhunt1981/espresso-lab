-- =====================================================================
-- Espresso Lab — Community-Kaffee-Bibliothek
-- SQL-Schema v2 (gehärtet, Security-Hardening nach LLM Security Council)
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
-- Ausführen: Supabase Dashboard → SQL Editor → New Query → einfügen → Run
-- Idempotent: kann sowohl auf frischem Projekt als auch zur Nachrüstung
-- einer bestehenden v1-Tabelle ausgeführt werden.
-- =====================================================================

-- 1. Erweiterung für schnelle ILIKE '%...%'-Suche (Fix #5)
create extension if not exists pg_trgm;

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
    on public.coffees using gin (search_text gin_trgm_ops);

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

-- =====================================================================
-- Nach dem Ausführen verifizieren:
--   → Dashboard → Database → Tables → coffees → Badge „RLS Enabled"
--   → Module → pg_trgm ist aktiv
--   → Test: mit dem anon key per REST einen INSERT mit 10MB-Text
--     oder DELETE-Versuch senden — beides muss fehlschlagen.
-- =====================================================================
