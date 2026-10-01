# KleinWeiter

Schweizer Secondhand-Marktplatz für Kinder (1 Monat bis einschliesslich 16 Jahre). Angelegt am 1. Oktober 2026.

## Stand

Implementierter Quellstand mit separater Designvorschau. NICHT veröffentlicht und noch NICHT für echte Verkäufe freigegeben.

- Fünf verpflichtende Alterswelten für Suche und Inserate, mit verschiedenen Farben und Formen.
- CHF, Kategorien, Suche, Sortierung, responsive Oberfläche.
- Anmeldung mit ChatGPT über Sites; Profile und private Kontaktdaten.
- D1 für Inserate, Gebote und Profile; R2 für eigene Produktfotos.
- Auktionen mit CHF 1 Mindestschritt und optionalem Sofortkauf.
- Serverseitige Identitäts-/Eigentumsprüfungen, konkurrierende Schreibzugriffe geschützt durch revisionsgebundene Updates.
- Endzeit wird serverseitig durchgesetzt; abgelaufene Auktionen werden beim nächsten API-Aufruf abgeschlossen.
- Käufer-/Verkäuferkontakt erst nach abgeschlossenem Verkauf, Zahlung und Versand direkt vereinbart.
- Pflichtbestätigung Kinderartikel. Automatische Bild-/Textprüfung ist bewusst noch nicht implementiert.

## Validierung

TypeScript-Prüfung erfolgreich. Generierte Drizzle-Migration mit vier Tabellen und Suchindizes.
API-Logik mit isoliertem SQLite-Test: Pflichtfelder, Altersbereich, Bildbesitz, eigene Gebote, Mindestgebot, Kaufbestätigung, Sofortkauf, erneuter Kauf, Kontaktschutz, Authentifizierung, Origin-Prüfung, Ablauf und konkurrierende Updates geprüft.
Designvorschau im Browser gerendert. WebMCP-Alterswahl mit gültigem und ungültigem Input geprüft.
Tests ersetzen keine Prüfung unter Cloudflare D1/R2 oder einen vollständigen Test mit zwei echten Konten.

## Konkreter Blocker

Die Windows-Ausführungsumgebung verweigert von Node gestartete Unterprozesse mit `spawn EPERM`, auch nach zusätzlicher Berechtigung. Die normale Installation mit Lifecycle-Skripten, Vinext-Vorschau und Produktionsbuild können deshalb nicht erfolgreich abgeschlossen werden. Pakete wurden für Quellcodeprüfung mit `--ignore-scripts` installiert. Keine Schutzmassnahmen wurden deaktiviert.

Das in den Sites-Anweisungen genannte Plugin-Skript `scripts/build-site.mjs` fehlt zusätzlich im installierten Plugin 0.1.75. `site-workflow.mjs` bzw. der reguläre Projektbuild müssen in einer funktionierenden Umgebung geprüft werden.

Site wurde privat registriert. Identität in `.openai/hosting.json` unbedingt wiederverwenden; keine zweite Site erstellen. Keine Produktionsversion oder Bereitstellung wurde erstellt. Keine Zugangsdaten im Projekt.

## Fortsetzen

1. In einer Umgebung mit erlaubten Node-Unterprozessen reguläre Installation mit vorhandenem Lockfile wiederholen.
2. `npm run build` ausführen und eventuelle Laufzeitfehler beheben.
3. Die vorhandene Migration lokal anwenden; unter echtem D1/R2 mit mindestens zwei Testkonten prüfen (Upload, Gebote, Sofortkauf, Ablauf, unzulässiger Kontaktzugriff).
4. Aktuelle Sites-Hosting-Anleitung verwenden, bestehende Site-ID beibehalten, privat veröffentlichen und erfolgreichen Deploymentstatus überprüfen.
5. Öffentliche Freigabe getrennt vornehmen. Es ist keine öffentliche Freigabe erfolgt.

`node prepare-tests.mjs` und `node test-market.mjs` führen die isolierten API-Tests aus. `node node_modules/typescript/bin/tsc --noEmit` prüft TypeScript.
`generate-migration.mjs` war ein einmaliger Helfer für die erste Migration. Nach einer Bereitstellung nicht erneut ausführen oder angewandte Migrationen überschreiben.

Die separate HTML-Designvorschau verwendet denselben React-Client. Sie ist keine eigenständige funktionsfähige Handelsplattform, speichert keine Angebote und führt keine Käufe aus.

## Inspirationsbilder

Nur Beispielbilder, keine echten Angebote; Quellen in `app/market.tsx`. Fremde Produktbilder von Purebaby, Alza und Bike Club. Nutzungsrechte wurden nicht geklärt; vor öffentlichem kommerziellem Einsatz durch eigene oder lizenzierte Bilder ersetzen. Echte Inserate benötigen eigene Uploads.

## Offene Ausbaupunkte

Automatische/manuelle Inhaltsprüfung, integrierte Zahlungen, Benachrichtigungen, weitergehende Moderation und Account-Verwaltung sind nicht Bestandteil dieses Quellstands. Der aktuelle Login nutzt ChatGPT, keine separate E-Mail-/Passwortregistrierung.
