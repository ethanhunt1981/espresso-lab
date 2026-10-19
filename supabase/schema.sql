-- =====================================================================
-- Espresso Lab — Community-Kaffee-Bibliothek
-- SQL-Schema für Supabase
--
-- Ausführen: Supabase Dashboard → SQL Editor → New Query → einfügen → Run
-- =====================================================================

-- 1. Tabelle für Kaffee-Profile (jede Zeile = ein Shots-Eintrag mit
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
    notes         text,                       -- Cupping-Notizen, z.B. "blaubeerige Süße, cremiger Body"
    author_name   text,                       -- Spitzname des Contributors (optional)
    created_at    timestamptz not null default now()
);

-- Komfort: automatisch gepflegte Such-Spalte über Marke + Name + Herkunft + Notizen
alter table public.coffees add column if not exists search_text text
    generated always as (
        lower(coalesce(brand, '') || ' ' || coalesce(coffee_name, '') || ' ' ||
              coalesce(origin, '') || ' ' || coalesce(notes, ''))
    ) stored;

-- Indizes für Textsuche und Sortierung
create index if not exists coffees_search_idx  on public.coffees using gin (to_tsvector('simple', search_text));
create index if not exists coffees_created_idx on public.coffees (created_at desc);
create index if not exists coffees_brand_idx   on public.coffees (lower(brand));

-- 2. Security: RLS ist über die Projekt-Optionen automatisch aktiv —
--    hier die exakt benötigten Regeln ergänzen:

-- a) Jeder darf lesen (auch anonyme Besucher der Website)
drop policy if exists "Jeder darf Kaffees lesen" on public.coffees;
create policy "Jeder darf Kaffees lesen"
    on public.coffees for select
    to anon, authenticated
    using (true);

-- b) Jeder darf einen Eintrag anlegen (Kaffee hinterlegen), ohne Login
drop policy if exists "Jeder darf einen Kaffee anlegen" on public.coffees;
create policy "Jeder darf einen Kaffee anlegen"
    on public.coffees for insert
    to anon, authenticated
    with check (
        -- Mindestanforderungen auch datenbankseitig durchsetzen
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
--    die Policies umgehst.
