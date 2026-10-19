/**
 * Espresso Lab — Backend-Konfiguration
 *
 * Die Werte hier sind bewusst öffentlich: Der Supabase "anon public key"
 * ist für die Verwendung im Browser vorgesehen und schützt nichts.
 * Die eigentliche Kontrolle läuft über die Row-Level-Security-Regeln
 * (siehe supabase/schema.sql): anonymes Lesen + Einfügen erlaubt,
 * Ändern/Löschen nur über das Supabase-Dashboard (Projekt-Inhaber).
 *
 * Einfügen: Supabase Dashboard → Project Settings → API Keys →
 *   - Project URL        → SUPABASE_URL
 *   - anon / public key  → SUPABASE_ANON_KEY
 */

window.ESPRESSO_LAB_CONFIG = {
    SUPABASE_URL: 'https://aizvoccuyuzmnpedolbu.supabase.co',
    SUPABASE_ANON_KEY: 'sb_publishable_qvdROpWTP1yFBnKliRVrgw_ICjQJomE'
};
