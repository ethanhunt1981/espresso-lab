-- =====================================================================
-- Espresso Lab — Security-Hardening Update v2.1 (Advisor-Fixes)
--
-- Behebt die 5 Security-Advisor-Warnungen des Supabase-Dashboards:
--   * „Extension in Public" (public.pg_trgm)
--   * „Public/Signed-In Can Execute SECURITY DEFINER Function"
--     (public.check_coffee_rate_limit(), public.rls_auto_enable())
--
-- Ausführen: Supabase Dashboard → SQL Editor → New Query → einfügen → Run
-- Idempotent: mehrfach ausführbar, keine Fehler bei bereits erledigten Schritten.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. pg_trgm aus 'public' in das 'extensions'-Schema umziehen
--    (Best Practice: Extensions liegen NIE im public-Schema)
-- ---------------------------------------------------------------------
create schema if not exists extensions;

do $$
begin
    -- Nur verschieben, wenn es wirklich noch in 'public' liegt
    if exists (
        select 1
        from pg_extension e
        join pg_namespace n on n.oid = e.extnamespace
        where e.extname = 'pg_trgm' and n.nspname = 'public'
    ) then
        alter extension pg_trgm set schema extensions;
    end if;
end $$;

-- ---------------------------------------------------------------------
-- 2. check_coffee_rate_limit(): EXECUTE entziehen
--    Die Funktion läuft NUR als BEFORE INSERT Trigger intern — der
--    PostgreSQL-Trigger-Mechanismus braucht kein EXECUTE-Recht des
--    einfügenden Nutzers. Direkte API-Aufrufe werden so unterbunden.
-- ---------------------------------------------------------------------
revoke execute on function public.check_coffee_rate_limit() from public;
revoke execute on function public.check_coffee_rate_limit() from anon;
revoke execute on function public.check_coffee_rate_limit() from authenticated;

-- Suchpfad der SECURITY DEFINER Funktion fixieren
-- (inkl. 'extensions', da pg_trgm dorthin gezogen ist)
alter function public.check_coffee_rate_limit() set search_path = public, extensions;

-- ---------------------------------------------------------------------
-- 3. rls_auto_enable(): Falls die Funktion existiert (von Supabase
--    selbst angelegt), bekommt der Anfang auch komplett keinen Zugriff.
-- ---------------------------------------------------------------------
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
-- Nach dem Ausführen:
--   → Security Advisor öffnen und „Refresh" klicken — alle 5 Warnungen
--     sollten verschwinden (0 Errors, 0 Warnings).
--   → Rate-Limit-Trigger bleibt WIRKSAM (Trigger braucht kein EXECUTE).
-- =====================================================================
