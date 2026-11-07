# Espresso-Lab Kaffee-Bibliothek

Dieses Projekt hält den Workflow für transparente Rezeptempfehlungen in der
Community-Kaffee-Bibliothek von Espresso Lab fest.

- Workflow: [.opencode/skills/espresso-bibliothek.md](.opencode/skills/espresso-bibliothek.md)
- Website: <https://espresso-lab-jade.vercel.app/>

Community-Einträge dürfen keine erfundenen Verkostungen oder Messwerte
vortäuschen. Der Scheduler plant 1–3 Veröffentlichungsversuche pro UTC-Tag zu
wechselnden Stunden. Veröffentlicht wird nur, wenn der Kaffee auf einer
offiziellen Rösterseite verifiziert werden kann; bei Unsicherheit wird der Lauf
ohne Eintrag beendet.

## GitHub Actions einrichten

1. Auf GitHub unter **Settings → Secrets and variables → Actions** das Repository-
   Secret `OPENROUTER_API_KEY` anlegen. Den Schlüssel nicht committen oder im Chat
   teilen.
2. GitHub Actions aktivieren und diese Änderung in den Default-Branch pushen.
3. Unter **Actions → Espresso Library Scheduler** einen manuellen **Preview**-
   Lauf testen. Er recherchiert und bereitet einen Vorschlag vor; Website und
   Datenbank sind in diesem Modus technisch für den Browser blockiert.
4. Erst nach erfolgreichem Preview unter **Variables** die Repository-Variable
   `ESPRESSO_AUTO_PUBLISH_ENABLED` mit dem Wert `true` setzen. Erst dann sind
   geplante und manuelle Veröffentlichungen freigeschaltet.

Der geplante Lauf prüft stündlich (UTC), ob einer der für diesen Tag deterministisch
zufällig verteilten Veröffentlichungstermine erreicht ist. Die Anzahl pro Tag ist
1–3. Vor jedem Post prüft er die heutigen Einträge, damit Nutzerbeiträge mitzählen
und das Tageslimit nicht überschritten wird. Die OpenRouter-Route ist zunächst
`cohere/north-mini-code:free`; das Modell unterstützt Tool-Aufrufe, kann als
kostenlose Route aber Rate-Limits oder Verfügbarkeitsprobleme haben. In solchen
Fällen wird nicht ungeprüft veröffentlicht.

Die automatische Veröffentlichung bleibt gesperrt, bis das Secret gesetzt, der
Preview-Lauf erfolgreich und die Repository-Variable ausdrücklich aktiviert ist.
