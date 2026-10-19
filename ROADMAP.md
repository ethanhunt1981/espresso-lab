# 🗺️ Roadmap — Community-Kaffee-Bibliothek

Ziel: Jeder Kaffeefan kann ohne Registrierung und ohne GitHub-Konto einen Kaffee
(Marke, Herkunft, Röstgrad) hinterlegen, seine Einstellungen und Ergebnisse teilen
und die Profile anderer direkt in der App laden und vergleichen.

Infrastruktur: GitHub Pages (statisch, wie bisher) + **Supabase** (kostenlose
Postgres-Datenbank) für die gemeinsame Kaffee-Profile.

---

## Phase 0 — Vorbereitung (Repository-Inhaber) ✅

> Nichts am Code — nur Konto & Konfiguration.

- [x] Supabase-Account anlegen (kostenlos, GitHub-Login möglich)
- [x] Neues Supabase-Projekt erstellen (Region: EU-Central)
- [x] SQL-Schema ausführen (Tabelle `coffees` → `supabase/schema.sql`)
- [x] Project-URL + anon key hinterlegen (`js/config.js`)

## Phase 1 — Datenmodell & Backend-Anbindung ✅

- [x] **SQL-Schema** `supabase/schema.sql`:
      Tabelle `coffees` (marke, name, herkunft, röstgrad, prozess,
      einstellungen: dosis/mahlgrad/temp/druck/zeit,
      ergebnisse: ey/tds/säure/süße/bitterkeit, notiz, ersteller-name, zeitstempel)
- [x] **Row Level Security:** anonymes Lesen + anonymes Einfügen erlaubt,
      Löschen/Ändern nur für Inhaber (über Supabase-Dashboard)
- [x] **Config-Mechanismus:** `js/config.js` mit Supabase-URL und anon key —
      App läuft auch ohne Werte (dann localStorage-Fallback)
- [x] `supabase-js` per CDN einbinden (kein Build-Step nötig)

## Phase 2 — UI: Kaffee-Bibliothek ✅

- [x] Neuer App-Bereich „Kaffee-Bibliothek" (Tab neben den Diagrammen)
- [x] **Hervorgehobenes Banner** am Seitenanfang mit CTA-Buttons
      („Jetzt entdecken" / „Mein Shot teilen") — für maximale Sichtbarkeit
- [x] Kartenansicht aller Community-Kaffees: Marke, Herkunft, Röstgrad,
      geteilte Einstellungen + Ergebnis-Chips (EY%, TDS%, Süße/Säure/Bitter)
- [x] **Profil laden:** Klick setzt alle Regler auf die gespeicherten Werte
- [x] Suche/Filter: Textsuche (Marke/Name/Herkunft/Notiz), Filter Röstgrad
- [x] Sortierung: neueste zuerst
      *(beste Bewertung → Phase 5, sobald Bewertungen existieren)*

## Phase 3 — Shot speichern & Profil anlegen ✅

- [x] Dialog „Mein Shot": Formular (Bohnen-Daten + optionaler Spitzname +
      Cupping-Notiz), gefüllt mit aktuellen Reglerwerten + berechneten Ergebnissen
- [x] Validierung (Pflichtfelder: Marke + Name des Kaffees;_limits auch
      datenbankseitig im SQL-Check erzwungen)
- [x] Wiederholter Shot am selben Kaffee → zusätzlicher Eintrag
      (Profile mit identischer Marke/Name gruppiert die Bibliothek aktuell
      noch nicht — Vergleichsansicht folgt in Phase 5)
- [x] „Profil ohne Shot anlegen" (Bohne zuerst, Ergebnisse später)

## Phase 4 — Fallback & Teilen (nicht von Supabase abhängig) — teilweise

- [x] localStorage-Fallback: Profile lokal speichern (Tag „nur lokal",
      inkl. Löschen solange noch kein Supabase-Write gelang)
- [x] Share-Link: Profil Base64-codiert als URL-Parameter (`#profil=...`) —
      Absender kann teilen, auch ohne Backend-Eintrag; Empfänger öffnet den
      Link → Regler werden automatisch gesetzt
- [ ] Export/Import als JSON-Datei

## Phase 5 — Verfeinerung (nach dem ersten Deployment)

- [ ] Mehrfach-Ergebnisse pro Kaffee: Mittelwerte + Abweichung darstellen
- [ ] „Vergleichen": 2–3 Kaffee parallel (Einstellungen + Geschmack)
- [ ] Bewertungen am Profil (Daumen hoch/runter, anonym, Missbrauch begrenzt)
- [ ] Mod-Features: eigene Einträge bearbeiten/löschen
- [ ] Spam-Schutz verfeinern (z.B. Cloudflare Turnstile)
- [ ] Übersetzung der UI (EN-Variante parallel zum DE-Original)

---

## Meilensteine

| Meilenstein | Inhalt | Status |
|---|---|---|
| M1 | Phase 0 fertig (Supabase steht) | ✅ erledigt |
| M2 | Phase 1+2: Bibliothek sichtbar, Profile ladbar | ✅ erledigt |
| M3 | Phase 3: Speichern funktioniert live | ✅ erledigt |
| M4 | Phase 4: Fallback + Share-Link | 🔶 fast fertig (JSON-Export offen) |
| M6 | 🔒 Security-Hardening: RLS, Constraints, Rate-Limit, Frontend-Härtung | ✅ erledigt & verifiziert (Phase S1+S2) — Details siehe interne Security-Roadmap (privat) |
| M5 | Öffentlicher Aufruf (Reddit r/espresso, Kaffee-Foren) | offen |
| M7 | Phase S3: Supply-Chain-Härtung (Versions-Pinning, SRI, CSP) | offen |

---

## 🔒 Security

Nach dem Feature-Release wurde der Code durch ein adversariales
LLM-Security-Council geprüft. Die daraus umgesetzten Härtings:

- Row Level Security zwingend aktiviert (nur Lesen + Anlegen für anonyme Nutzer)
- Harte Längen-/Wertebereichs-Constraints auf allen Datenbank-Spalten
- Serverseitiges Rate-Limiting gegen Bot-Flooding
- Frontend-Härtung: XSS-sicheres Rendering (standard: `createElement` +
  `textContent`), validierte Share-Links, sanatizerte Suche, moderne Encoder

Konkrete Probe-Angriffe (REST-DELETE, Oversize-Insert, NaN-Injection) wurden
nach der Migration verifiziert abgeblockt. Detaillierte Findings, Patches und
die Security-Roadmap liegen **privat** beim Inhaber (`security/`, gitignored) —
bewusst nicht im öffentlichen Repo.
