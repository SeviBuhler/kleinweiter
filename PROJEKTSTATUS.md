# kleinweiter – Stand 1. Oktober 2026

Das Desktop-Projekt wurde nach `outputs/kleinweiter` übernommen und auf Next.js 16, Vercel und Supabase migriert. Bestehendes Design und Kernabläufe wurden weiterverwendet. Cloudflare D1/R2, Vinext und ChatGPT-Header-Anmeldung wurden durch PostgreSQL-Funktionen, Supabase Auth und Storage ersetzt. Fremde Inspirationsfotos wurden durch eigene SVG-Illustrationen ersetzt. Das Desktop-Original blieb unangetastet; die bisherige Sites-Identität liegt im Archiv.

## Eingerichtet

Das Git-Repository ist mit https://github.com/SeviBuhler/kleinweiter.git verbunden. Neue Änderungen werden lokal committed; der Nutzer pusht selbst. Keine Vercel-Veröffentlichung wurde vorgenommen.

Supabase-Projekt `bhogyeublnutiyfjwmou` ist verbunden. Migrationen `20261001000100` und `20261001000200` wurden erfolgreich angewandt und in der Migrationshistorie registriert. Alle Anwendungstabellen sind mit RLS geschützt. Handelsaktionen und Uploadreservierungen laufen ausschliesslich über PostgreSQL-Funktionen. Bildspeicher ist privat und auf 4 MB begrenzt. Profile werden bei Registrierung automatisch angelegt.

E-Mail-Bestätigung ist aktiviert; anonyme Anmeldung ist deaktiviert. Anmeldelinks verwenden einen PKCE-Callback. Codes haben acht Stellen; Codes und Links sind 600 Sekunden gültig. Eigene E-Mail-Vorlagen sind in diesem Free-Projekt ohne SMTP oder Pro nicht verfügbar. Standard-E-Mail-Versand ist auf Supabase-Teamadressen begrenzt; weitere Tester benötigen eigenen SMTP-Versand.

Lokale `.env.local` ist eingerichtet und Git-ignoriert. Die Vercel-Adresse ist noch nicht bekannt; Site URL und Callback sind vorerst `http://localhost:3000` und `http://localhost:3000/auth/callback`. Vor Deployment `NEXT_PUBLIC_SITE_URL` sowie Supabase Site URL und Redirect URLs auf die echte Vercel-Adresse setzen. Die übrigen Verbindungswerte separat als Vercel-Umgebungsvariablen eintragen.

## Geprüft

Installation und Next.js-Produktionsbuild unter Windows waren erfolgreich; der frühere `spawn EPERM`-Blocker trat bei diesem Aufbau nicht auf. Drei automatische Tests bestanden, darunter SQL-Berechtigungs- und Handelstests mit zwei simulierten Identitäten in einer isolierten PostgreSQL-Engine.

Die tatsächlichen PostgreSQL-Funktionen wurden zusätzlich auf Supabase mit zwei transienten Datenbankidentitäten geprüft: Eigentum, Gebote, Kauf, Kontakte und Rechte. Alle Testdaten wurden zurückgerollt. Der direkte Live-API-Test bestätigt öffentliche Angebotssuche und verweigerte anonyme Tabellen-/Schreibzugriffe. Skripte: `scripts/verify-supabase.sql` und `scripts/verify-api.mjs`.

## Noch offen

Der Nutzer hat den echten E-Mail-Test vorerst ausgelassen. Anmeldung, Session-Erneuerung und tatsächlicher Foto-Upload mit zwei echten Konten sowie gleichzeitige Gebote auf Vercel müssen noch geprüft werden. Die Datenbanktests ersetzen diese vollständigen Nutzerabläufe nicht.

Die Website ist nicht für echte Verkäufe freigegeben. Automatische Moderation, integrierte Zahlungen, Meldungen, Accountlöschung, Betriebs-/Datenschutzinformationen und Backupabläufe fehlen noch. Zahlung und Übergabe werden direkt vereinbart. Verwaiste Uploads werden noch nicht automatisch gelöscht. README enthält Einrichtungshinweise; TESTPLAN beschreibt die verbleibenden Integrationsprüfungen.
