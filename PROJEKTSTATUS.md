# kleinweiter – Stand 2. Oktober 2026

Next.js/React/TypeScript, Vercel und Supabase ersetzen den ursprünglichen Vinext-/Cloudflare-Aufbau. Das Desktop-Original blieb unverändert. Eigene SVG-Illustrationen ersetzen fremde Inspirationsbilder.

## Betrieb

- GitHub: https://github.com/SeviBuhler/kleinweiter.git. Der Nutzer pusht lokale Commits selbst.
- Website: https://kleinweiter.vercel.app. Supabase- und Google-Login-Variablen sind in Vercel gesetzt; Google-Anmeldung ist veröffentlicht.
- Supabase: `bhogyeublnutiyfjwmou`. Migrationen `20261001000100`, `20261001000200` , `20261002000100` und `20261002000200` sind angewandt und registriert.
- Google-OAuth-Projekt: `kleinweiter-sevi-20261001`. Google-Anmeldung funktioniert mit beiden Testkonten. Freigabe für weitere Tester hängt vom Google-Audience-Status ab.
- Keine Zugangsdaten im Git. Lokale Umgebungsdatei ist ignoriert. Kein service_role-Key in der App.

## Funktionen und Sicherheit

Alterswelten, Suche, Kategorien, CHF-Auktionen, Sofortkauf, eigene Fotos, Anzeigenamen und Kontoseiten sind vorhanden. Zahlung und Übergabe vereinbaren die Beteiligten direkt. Kontakte werden erst nach Kauf/Auktionsabschluss an Verkäufer und Gewinner freigegeben.

RLS und entzogene direkte Tabellenrechte schützen die Daten. Schreiben erfolgt durch geprüfte PostgreSQL-Funktionen. Privat gespeicherte Rasterbilder sind auf 4 MB begrenzt. Anmeldung verwendet Supabase Auth und einen serverseitigen PKCE-Callback.

Neue Inseratverwaltung: eigene aktive Inserate lassen sich vor dem ersten Gebot bearbeiten oder zurückziehen. Preis und Auktionsende bleiben beim Bearbeiten unverändert. Zurückgezogene Inserate bleiben im Konto und verschwinden aus der Suche. Datenbanksperren und Versionsprüfung verhindern Änderungen bei inzwischen eingegangenen Geboten oder veralteten Formularen. Die neue Oberfläche ist mit Commit `120d784` auf GitHub und Vercel veröffentlicht.

## Prüfung

Installation, Produktionsbuild und drei automatische Tests erfolgreich. SQL-Tests prüfen mit zwei Identitäten Eigentum, Bearbeiten, veraltete Änderungen, Zurückziehen, Gebotssperren, Kauf und Kontaktrechte. Live-Supabase-Tests verwenden eine Transaktion mit vollständigem Rollback und bestanden ebenfalls.

Mit zwei echten Google-Konten wurden Anmeldung, Foto-Upload, Inseraterstellung und Eigentum geprüft. Ein ausdrücklich als Test markiertes Inserat erhielt ein gültiges Gebot; ein zu niedriges Gebot wurde abgelehnt. Der Sofortkauf wurde bestätigt und entfernte das Angebot aus der öffentlichen Suche. Es fand keine Zahlung statt. Kaufhistorie und gegenseitige Kontaktanzeige wurden auf beiden echten Kontoseiten bestätigt. Der Testartikel verbleibt als Verkaufshistorie. Ein zweiter klar markierter Testartikel wurde auf Vercel bearbeitet, nach Neuladen mit geändertem Titel geprüft und zurückgezogen. Abbrechen des Bestätigungsdialogs liess ihn aktiv. Nach Zurückziehen bleibt er im Konto sichtbar und fehlt im öffentlichen Feed (HTTP 200, leere Angebote).

Noch offen: gleichzeitige Handelsaktionen auf dem gehosteten System und Session-Erneuerung über längere Zeit. Datenbanksperren sind implementiert; die bisherigen Tests ersetzen keinen echten Paralleltest.

## Neue Meldefunktion

Angemeldete Nutzer können fremde aktive Inserate melden. Grund und Beschreibung sind erforderlich. Eine Meldung je Konto/Inserat und zehn pro 24 Stunden; keine direkten Tabellenrechte. Der damalige Inseratstand wird privat als Snapshot gespeichert. Nur der Datenbankbetreiber kann Prüfergebnisse über `review_listing_report` dokumentieren. Die Auktion bleibt aktiv; kein automatisches Sperren oder Stornieren. Anleitung: `MODERATION.md`.

Die Datenbankmigration ist angewandt. Automatische Rechte-/Funktionstests und Produktionsbuild bestanden. Die neue Oberfläche braucht den nächsten GitHub-Push und Vercel-Build; der echte Browser-Test steht danach an.

## Vor breiterem Einsatz

Kleine geschlossene Testphase empfohlen. Administrative Sperren/Stornierungen, Accountlöschung, Betriebs-/Datenschutzinformationen, Backups und Bereinigung verwaister Uploads fehlen. Automatische Inhaltsprüfung und integrierte Zahlungen sind nicht implementiert.
