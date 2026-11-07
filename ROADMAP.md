# 🗺️ Roadmap — Community Coffee Library

Goal: Any coffee enthusiast can without registration and without GitHub account leave behind a coffee
(brand, origin, roast level) enter, share its settings and results share and other profiles load directly in the app and compare.

Infrastructure: GitHub Pages (static, as before) + **Supabase** (free
Postgres database) for the common coffee profiles.

---

## Phase 0 — Preparation (Repository Owner) ✅

> Nothing about the code — just account & configuration.

- [x] Supabase account create (free, GitHub login possible)
- [x] New Supabase project create (Region: EU-Central)
- [x] SQL-Schema ausführen (Tabelle `coffees` → `supabase/schema.sql`)
- [x] Project-URL + anon key hinterlegen (`js/config.js`)

## Phase 1 — Data Model & Backend Binding ✅

- [x] **SQL-Schema** `supabase/schema.sql`:
      Tabelle `coffees` (marke, name, herkunft, röstgrad, prozess,
      einstellungen: dosis/mahlgrad/temp/druck/zeit,
      ergebnisse: ey/tds/säure/süße/bitterkeit, notiz, ersteller-name, zeitstempel)
- [x] **Row Level Security:** anonymes Lesen + anonymes Einfügen erlaubt,
      Löschen/Ändern nur für Inhaber (über Supabase-Dashboard)
- [x] **Config-Mechanismus:** `js/config.js` with Supabase-URL and anon key —
      App läuft auch ohne Werte (dann localStorage-Fallback)
- [x] `supabase-js` per CDN einbinden (kein Build-Step nötig)

## Phase 2 — UI: Coffee Library ✅

- [x] Neuer App-Bereich „Kaffee-Bibliothek" (Tab neben den Diagrammen)
- [x] **Hervorgehobenes Banner** am Seitenanfang mit CTA-Buttons
      („Jetzt entdecken" / „Mein Shot teilen") — für maximale Sichtbarkeit
- [x] Kartenansicht aller Community-Kaffees: Marke, Herkunft, Röstgrad,
      geteilte Einstellungen + Ergebnis-Chips (EY%, TDS%, Süße/Säure/Bitter)
- [x] **Profil laden:** Klick setzt alle Regler auf die gespeicherten Werte
- [x] Suche/Filter: Textsuche (Marke/Name/Herkunft/Notiz), Filter Röstgrad
- [x] Sortierung: neueste zuerst
      *(beste Bewertung → Phase 5, sobald Bewertungen existieren)*

## Phase 3 — Shot speichern & Profile erstellen ✅

- [x] Dialog „Mein Shot": Formular (Bohnen-Daten + optionaler Spitzname +
      Cupping-Notiz), gefüllt mit aktuellen Reglerwerten + berechneten Ergebnissen
- [x] Validierung (Pflichtfelder: Marke + Name des Kaffees;_limits auch
      datenbankseitig im SQL-Check erzwungen)
- [x] Wiederholter Shot am selben Kaffee → zusätzlicher Eintrag
      (Profile mit identischer Marke/Name gruppiert die Bibliothek aktuell
      noch nicht — Vergleichsansicht folgt in Phase 5)
- [x] „Profil ohne Shot anlegen" (Bohne zuerst, Ergebnisse später)

## Phase 4 — Fallback & Teilen (nicht von Supabase abhängig) ✅

- [x] localStorage-Fallback: Profile lokal speichern (Tag „nur lokal",
      inkl. Löschen solange noch kein Supabase-Write gelang)
- [x] Share-Link: Profil Base64-codiert als URL-Parameter (`#profil=...`) —
      Absender kann teilen, auch ohne Backend-Eintrag; Empfänger öffnet den
      Link → Regler werden automatisch gesetzt
- [x] Export/Import als JSON-Datei: ⬇-Button pro Karte (Download),
      📥-Import in der Bibliothek-Leiste (mehrere Profile pro Datei möglich);
      Import-Profile werden vor dem Speichern auf die DB-Constraints
      validiert/klemmen — Rate-Limit-Überläufe landen lokal mit „nur lokal"-Tag

## Phase 5 — Refinement (after the first deployment)

- [x] **Mehrfach-Ergebnisse pro Kaffee: Mittelwerte (Ø) darstellen** —
      Einträge desselben Kaffees (Marke + Name, case-insensitiv) werden
      gruppiert; die Karte zeigt den **neuesten Shot** mit Accent
      „Neuester Shot"-Präfix, Ergebnis-Chips zeigen bei n≥2 den
      **Ø-Mittelwert** über alle Shots + einen „N Shots"-Chip
      *(Abweichungen/Spannweite: später bei Bedarf)*
- [x] **„Vergleichen": bis zu 3 Kaffee parallel** — ⚖-Button an jeder Karte
      (ausgewählte Karten erhalten amber-Rahmen), Vergleichstabelle über der
      Bibliothek mit allen BoPoln- + Brühparameter + Ergebnissen + Autor;
      Auswahl bereinigt sich selbst bei Suche/Filter, ✕ schließt den Modus
- [x] **Bewertungen am Profil (Daumen 👍)** — anonym, eine Stimme pro
      Browser; SQL `supabase/schema_update_v2.2_votes.sql` ausführen
      (Tabelle `coffee_votes` with RLS, Unique-Doppelvotenschutz
      `(coffee_id, voter_token)`, Rate-Limit 20/min); UI: 👍-Button pro
      Karte mit Zähler (Summe über alle Shots der Gruppe), eigene Stimme
      wird via `espressoLabMyVotes` gemerkt, Token aus
      `crypto.getRandomValues` (keine PII). Daumen runter bewusst weggelassen
      (positiver Fokus statt Negativ-Bewertungs-Wettbewerb)
- [ ] Mod-Features: eigene Einträge bearbeiten/löschen
- [ ] Spam-Schutz verfeinern (z.B. Cloudflare Turnstile)
- [ ] Übersetzung der UI (EN-Variante parallel zum DE-Original)

## Launch Polish (2026-10-20, direkt nach dem Reddit-Post)

- [x] **Bibliothek-Grid auf Desktop repariert:** Spaltenzahl richtet sich
      jetzt nach der echten Container-Breite
      (`grid-cols-[repeat(auto-fill,minmax(240px,1fr))]`) statt nach
      Viewport-Breakpoints — vorher wurden bei breitem Fenster 3 Spalten
      in ein schmales Panel gequetscht (Buttons umgebrochen, Leerraum-Scrollleiste)
- [x] **Vergleichstabelle scrollbar** (`overflow-x-auto`), Karten-Buttons
      umbrechbar (`flex-wrap`)
- [x] **Extraktionswissen kompakt:** volles Breitenband (`lg:col-span-12`
      unter allen drei Spalten mit 4 Karten — SCA-EY-Fenster, TDS-Stärke,
      Extraktionstreiber, Zeit-Kinetik; verknüpft jeweils die Diagramme
      *(Lektion: nach dem HTML-Edit fehlte `npm run build:css` → die
      neue Klasse `lg:col-span-12` war nicht im Build und das Panel
      saß auf 1/12-Breite. Regel: nach jedem HTML-Edit mit neuen
      Klassen SOFORT rebuilden und die Klasse im CSS verifizieren)*
- [x] **Drei Spalten auf gleichmäßige Höhe** gestretched (`items-start`
      entfernt), damit vor dem Wissensband kein Stufen-Leerraum entsteht;
      Simulations-Panel stapelt Inhalt oben bündig (kein `justify-between`,
      kein Umbruch zwischen Canvas/Waage/Buttons) und sammelt Überschuss
      nur am Panel-Ende — stabiles Panel-Verhalten bei jedem Tabwechsel

---

## Milestones

| Milestone | Content | Status |
|---|---|---|
| M1 | Phase 0 fertig (Supabase steht) | ✅ erledigt |
| M2 | Phase 1+2: Bibliothek sichtbar, Profile ladbar | ✅ erledigt |
| M3 | Phase 3: Speichern funktioniert live | ✅ erledigt |
| M4 | Phase 4: Fallback + Share-Link + JSON-Export/Import | ✅ erledigt |
| M6 | 🔒 Security-Hardening: RLS, Constraints, Rate-Limit, Frontend-Härtung | ✅ erledigt & verifiziert (Phase S1+S2) — Details siehe interne Security-Roadmap (privat) |
| M5 | Öffentlicher Aufruf (Reddit r/espresso, Kaffee-Foren) | ✅ **erledigt (2026-10-19):** englischer Post live auf Reddit r/espresso; deutschsprachige Kanäle (Kaffee-Netz & Co.) folgen; Follow-up-Kommentar geplant, sobald Phase 5.6 (EN-Übersetzung) online ist |
| M7 | Phase S3: Supply-Chain-Härtung (Version-Pinning, SRI, CSP, Tailwind-Lokal-Build, Favicon) | ✅ **erledigt & verifiziert (2026-10-20):** automatisierte Checks (Assets 200, SRI-Hash matcht CDN-Bytes, Tailwind-Klassenabdeckung 0 fehlend) + Inhaber-Sichtprüfung auf lokal & GitHub Pages — S3.6 abgeschlossen |

---

## 🔒 Security

After the feature-release was the code by an adversarial
LLM-Security-Council geprüft. The resulting hardenings:

- Row Level Security zwingend activated (only Reading + Inserting for anonymous users)
- Harte Längen-/Wertebereichs-Constraints on ALL Spalten inkl.
      `origin`/`process` (Fix #2 „Generated-Column-Bomb")
- Serverseitiges Rate-Limiting gegen Bot-Flooding
- Frontend-Härtung: XSS-sicheres Rendering (standard: `createElement` +
  `textContent`), validierte Share-Links, sanatizerte Suche, moderne Encoder

Concrete probe attacks (REST-DELETE, Oversize-Insert, NaN-Injection) were
nach der Migration verifiziert abgeblockt. Detailed findings, Patches and
die Security-Roadmap liegen **privat** beim Inhaber (`security/`, gitignored) —
bewusst nicht im öffentlichen Repo.

---

## 📝 Automation Status — November 7, 2026

- **Supabase:** Earlier inactivity warning; scheduled community profiles are intended to provide real database activity instead of synthetic keepalive traffic.
- **Scheduler:** `.github/workflows/coffee-library-scheduler.yml` uses OpenCode with OpenRouter. It remains disabled until GitHub secret `OPENROUTER_API_KEY` is added, a preview succeeds, and repository variable `ESPRESSO_AUTO_PUBLISH_ENABLED=true` is set.
