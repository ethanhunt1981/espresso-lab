-- =====================================================================
-- Espresso Lab — Schema-Update v2.2: Bewertungen (Daumen 👍)
--
-- Fügt die Tabelle `coffee_votes` hinzu:
--   * Eine Stimme pro Browser (anonymer voter_token, einmalig pro Kaffee)
--   * RLS: alle dürfen lesen + abgeben, niemand darf ändern/löschen
--   * Rate-Limit: max. 20 Bewertungen pro Minute global (Bot-Bremse)
--   * Unique-Constraint (coffee_id, voter_token) als Doppelt-Vote-Sperre
--
-- Ausführen: Supabase Dashboard → SQL Editor → New Query → einfügen → Run
-- =====================================================================

-- 1. Tabelle mit Doppelt-Vote-Schutz
create table if not exists public.coffee_votes (
    id            uuid primary key default gen_random_uuid(),
    coffee_id     uuid not null references public.coffees(id) on delete cascade,
    voter_token   text not null,                    -- anonymer Zufalls-Token eines Browsers (keine PII)
    created_at    timestamptz not null default now(),
    unique (coffee_id, voter_token)
);

create index if not exists coffee_votes_coffee_idx on public.coffee_votes (coffee_id);

-- 2. RLS + Defense in Depth (nur Lesen + Anlegen; nie Ändern/Löschen)
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

-- 3. Rate-Limit gegen Vote-Flooding (max. 20 pro Minute global)
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

-- ExecutEntzug analog schema v2.1 (Funktion läuft nur intern als Trigger)
revoke execute on function public.check_vote_rate_limit() from public;
revoke execute on function public.check_vote_rate_limit() from anon;
revoke execute on function public.check_vote_rate_limit() from authenticated;

-- =====================================================================
-- Nach dem Ausführen:
--   → Dashboard → Database → Tables: neue Tabelle `coffee_votes` sichtbar,
--     Badge „RLS Enabled"
--   → Security Advisor → Refresh: weiterhin 0 Warnings
-- =====================================================================
