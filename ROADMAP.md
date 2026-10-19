# 🗺️ Roadmap — Community-Kaffee-Bibliothek

Ziel: Jeder Kaffeefan kann ohne Registrierung und ohne GitHub-Konto einen Kaffee
(Marke, Herkunft, Röstgrad) hinterlegen, seine Einstellungen und Ergebnisse teilen
und die Profile anderer direkt in der App laden und vergleichen.

Infrastruktur: GitHub Pages (statisch, wie bisher) + **Supabase** (kostenlose
Postgres-Datenbank) für die gemeinsamen Kaffee-Profile.

---

## Phase 0 — Vorbereitung (Repository-Inhaber)

> Nichts am Code — nur Konto & Konfiguration.

- [ ] Supabase-Account anlegen (kostenlos, GitHub-Login möglich)
- [ ] Neues Supabase-Projekt erstellen (Region nah wählen, z.B. EU-Central)
- [ ] SQL-Schema ausführen (Tabelle `coffees` — Skript liefere ich)
- [ ] Project-URL + anon key notieren

## Phase 1 — Datenmodell & Backend-Anbindung

- [ ] **SQL-Schema** `supabase/schema.sql`:
      Tabelle `coffees` (marke, name, herkunft, roestgrad, prozess, varietät,
      einstellungen: dosis/mahlgrad/temp/druck/zeit,
      ergebnisse: ey/tds/säure/süße/bitterkeit, notiz, ersteller-name, zeitstempel)
- [ ] **Row Level Security:** anonymes Lesen + anonymes Einfügen erlaubt,
      Löschen/Ändern nur für Inhaber (über Supabase-Dashboard)
- [ ] **Config-Mechanismus:** `config.js` (lokal, nicht committet) mit
      Supabase-URL und anon key — App läuft auch ohne Werte
      (dann localStorage-Fallback)
- [ ] `supabase-js` per CDN einbinden (kein Build-Step nötig)

## Phase 2 — UI: Kaffee-Bibliothek

- [ ] Neuer App-Bereich „Kaffee-Bibliothek" (Tab neben den Diagrammen)
- [ ] Kartenansicht aller Community-Kaffee: Marke, Herkunft, Röstgrad,
      geteilte Einstellungen + Ergebnis-Shorties (EY%, TDS%,都非常)
- [ ] **Profil laden:** Klick setzt alle Regler auf die gespeicherten Werte
- [ ] Suche/Filter: Textsuche (Marke/Name), Filter Röstgrad
- [ ] Sortierung: neueste, beste Bewertung

## Phase 3 — Shot speichern & Profil anlegen

- [ ] Dialog „Mein Shot": Formular (Bohnen-Daten + optionaler Spitzname +
      Cupping-Notiz), gefüllt mit aktuellen Reglerwerten + berechneten Ergebnissen
- [ ] Validierung (Pflichtfelder: Marke + Name des Kaffees)
- [ ] Wiederholter Shot am **selben Kaffee** → zusätzliches Ergebnis am Profil
      (Vergleich mehrerer Referenzzoß-Versuche pro Kaffee)
- [ ] „Profil ohne Shot anlegen" (Bohne zuerst, Ergebnisse später)

## Phase 4 — Fallback & Teilen (nicht von Supabase abhängig)

- [ ] localStorage-Fallback: „Meine Shots & meine Bohnen" lokal speichern
- [ ] Share-Link: aktuelles Profil + Ergebnis als URL-Parameter — Absender
      kann teilen即使 ohne Backend-Eintrag, Empfänger öffnet Link → Regler + Anzeige
- [ ] Export/Import als JSON-Datei

## Phase 5 — Verfeinerung (nach dem ersten Deployment)

- [ ] Mehrfach-Ergebnisse pro Kaffee: Mittelwerte + Abweichung darstellen
- [ ] „Vergleichen": 2–3 Kaffee parallel (Einstellungen + Geschmack)
- [ ] Bewertungen an的市场 Profil (Daumen hoch/hin, anonym, Missbrauch begrenz)
- [ ] Mod-Features: eigene Einträge per „Geheim-URL" bearbeiten/löschen
- [ ] Spam-Schutz verfeinern (Rate-Limit via Cloudflare Turnstile o.ä.)
- [ ] Übersetzung der UI (EN-Layout parallel zur DE-Variante)

---

## Meilensteine

| Meilenstein | Inhalt | Status |
|---|---|---|
| M1 | Phase 0 fertig (Supabase steht) | offen |
| M2 | Phase 1+2: Bibliothek sichtbar, Profile ladbar | offen |
| M3 | Phase 3: Speichern funktioniert live | offen |
| M4 | Phase 4: Fallback + Mobile polish | offen |
| M5 | Öffentlicher Aufruf (Reddit r/espresso, Kaffee-Foren) | offen |
