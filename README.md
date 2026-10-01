# kleinweiter

Schweizer Secondhand-WebApp für Kinderartikel, aufgebaut auf dem vorhandenen Desktop-Projekt. React/TypeScript und Next.js für Vercel; PostgreSQL, Auth und private Bildablage bei Supabase. Ohne Supabase-Einstellungen läuft eine klar gekennzeichnete Designvorschau. Keine Daten werden im Browser als angeblich echte Angebote gespeichert.

## Verbundenes Projekt

Das Supabase-Projekt `bhogyeublnutiyfjwmou` wurde eingerichtet. Beide Migrationen sind bereits angewandt und in der Migrationshistorie registriert. Nicht nochmals manuell ausführen. Lokale Verbindungswerte stehen in der Git-ignorierten `.env.local`; auf Vercel separat eintragen. Als Rücksprungadresse ist vorerst `http://localhost:3000/auth/callback` eingerichtet.

## Lokal starten

Voraussetzung: Node.js 22 oder neuer.

```powershell
npm ci
npm run dev
```

Öffne http://localhost:3000. Für einen Produktionsbuild: `npm run build`, dann `npm start`.

`npm test` prüft die echte SQL-Migration in einer isolierten PostgreSQL-Engine (PGlite), inklusive Zugriffsrechten und Abläufen mit zwei simulierten Identitäten. `npm run build` prüft zusätzlich TypeScript. GitHub Actions führt beides bei Pushes und Pull Requests aus.

## GitHub und Vercel: zuerst nur zeigen

Dieses Verzeichnis ist ein Git-Repository auf Branch `main`, verbunden mit [SeviBuhler/kleinweiter](https://github.com/SeviBuhler/kleinweiter). Die neuen Änderungen lokal prüfen und selbst hochladen:

```powershell
git remote add origin https://github.com/DEIN-NAME/kleinweiter.git
git push -u origin main
```

Auf Vercel: **Add New → Project → Import Git Repository**, dieses GitHub-Repository wählen. Framework **Next.js**, Root Directory **./**, Build Command `npm run build`, Output Directory automatisch. Eine eigene Domain ist nicht nötig; Vercel vergibt eine `*.vercel.app`-Adresse.

Für die reine Vorschau brauchst du keine Supabase-Schlüssel. Optional `NEXT_PUBLIC_DEMO_MODE=true` setzen. Nach Änderungen an Umgebungsvariablen neu deployen. Die Vorschau enthält eigene SVG-Illustrationen; keine fremden Produktbilder.

**Kosten:** Vercel Hobby ist für private, nicht kommerzielle Nutzung bestimmt. Den Tarif vor echtem Marktplatzbetrieb klären. Supabase Free enthält derzeit 500 MB Datenbank und 1 GB Bildspeicher; Grenzen, E-Mail-Versand und Pausierung beachten. GitHub-Verbindung allein ersetzt keine Datenbankmigration oder Auth-Konfiguration.

## Supabase verbinden

1. Neues Projekt `kleinweiter` anlegen, Region Europe. Starkes Datenbankpasswort selbst erzeugen und sicher speichern. **Enable Data API** einschalten; **Automatically expose new tables** ausschalten; automatische RLS kann eingeschaltet werden. Die Migration aktiviert RLS selbst und vergibt gezielte Rechte.
2. Für den einfachen Start im **SQL Editor** beide Dateien aus `supabase/migrations/` in aufsteigender Reihenfolge **einmal** auf einem frischen Projekt ausführen. Nicht erneut auf einem bereits migrierten Projekt ausführen.
3. Alternativ die offizielle Supabase-GitHub-Integration verwenden: Migration und `supabase/config.toml` sind vorbereitet. Vor Produktionssync `auth.site_url` und `auth.additional_redirect_urls` in `config.toml` auf deine Vercel-HTTPS-Adresse und deren `/auth/callback` ändern. Produktionsbranch `main` bewusst auswählen und **Deploy to production** konfigurieren. Automatische Preview-Branches sind optional; vor Aktivierung die Kosten prüfen. Wähle einen Migrationsweg und mische ihn nicht mit manueller SQL-Ausführung. Bei bereits manuell angewandter Migration zuerst die Migrationshistorie mit Supabase CLI abgleichen.
4. Standardmässig die Supabase-Anmeldelink-Vorlagen beibehalten. Die App verarbeitet den PKCE-Callback. Codes haben acht Stellen; Codes und Links sind zehn Minuten gültig. Eigene OTP-Vorlagen aus `supabase/templates/otp.html` sind optional und brauchen auf diesem Free-Projekt eigenen SMTP-Versand oder Pro; dann Magic Link und Confirm signup anpassen.
5. Unter Auth URL Configuration die Vercel-Adresse als Site URL setzen und exakt `https://DEINE-APP.vercel.app/auth/callback` zu Redirect URLs hinzufügen. `NEXT_PUBLIC_SITE_URL` in Vercel muss dieselbe App-Adresse enthalten. Für einen kleinen geschlossenen Pilotversuch neue Registrierungen deaktivieren und die Tester im Supabase-Dashboard anlegen. `shouldCreateUser: true` im Client umgeht eine deaktivierte Registrierung nicht.
6. Für fremde Testpersonen eigenen SMTP-Versand konfigurieren. Supabase-Standardversand ist eingeschränkt; ein Free-Datenbankprojekt garantiert keinen kostenlosen E-Mail-Versand an beliebige Empfänger. Bei breiterer Freigabe zusätzlich Supabase CAPTCHA aktivieren und in der Anmeldemaske anbinden.
7. `.env.example` nach `.env.local` kopieren und diese Werte eintragen. Dieselben Variablen auf Vercel für die gewünschte Umgebung setzen:

```dotenv
NEXT_PUBLIC_SUPABASE_URL=https://DEIN-PROJEKT.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
NEXT_PUBLIC_SITE_URL=https://DEINE-APP.vercel.app
NEXT_PUBLIC_DEMO_MODE=false
```

Nur den öffentlichen Publishable-Key verwenden. **Keine Secret-, service_role- oder Datenbankpasswörter in Git oder Browser-Code.** Die App benötigt keinen administrativen Schlüssel. Der Publishable-Key ist kein Sicherheitsgeheimnis; Zugriffsrechte werden durch Auth, RLS und Datenbankfunktionen durchgesetzt. Supabase kann später auch selbst gehostet werden; Betrieb, Updates und Backups liegen dann bei dir.

## Enthaltene Abläufe

- Fünf verpflichtende Alterswelten mit Farben und Formen: ab 1 Monat bis **unter** 3; 3 bis **unter** 6; 6 bis **unter** 10; 10 bis **unter** 13; 13 bis **einschliesslich** 16 Jahre. Die kurzen Namen `0–3` usw. sind Weltbezeichnungen; die genauen Grenzen stehen bei der Auswahl.
- CHF-Preise in ganzzahligen Rappen, Suche, Kinderkategorien und Sortierung.
- E-Mail-Link-Anmeldung (PKCE; optional Codes mit eigener E-Mail-Vorlage), öffentlicher Anzeigename, eigenes Inserat mit einem eigenen Produktfoto (JPG/PNG/WebP, maximal 4 MB wegen Vercels Request-Grenze).
- Auktion mit CHF 1 Mindestschritt, optionaler Sofortkauf und expliziter Kaufbestätigung. Kein Bieten auf eigene Angebote.
- Datenbanksperre pro Angebot und transaktionale Verarbeitung von Gebot und Verkauf. Ablauf wird nach Erwerb der Sperre erneut geprüft.
- Kontoübersicht mit Angeboten, Geboten und Käufen. E-Mail-Kontakt erscheint erst nach verkauftem Angebot, nur für Käufer und Verkäufer.
- Private Bildablage: öffentliche Anzeige nur für Bilder, die an Inserate gebunden sind; unveröffentlichte Uploads sind nur für ihren Eigentümer lesbar.
- Automatische Profilanlage bei neuer Registrierung; httpOnly-Sitzungscookies, Secure in Produktion, Origin-Prüfung bei API-Schreibzugriffen und Sicherheitsheader.

Zahlung und Übergabe werden direkt vereinbart. Ein Produktfoto pro Inserat ist bewusst der kleine Startumfang.

## Vor dem echten Pilotbetrieb prüfen

Siehe `TESTPLAN.md`. Die bisherigen Tests ersetzen **keinen** Test mit echten Supabase-Konten und Vercel. Insbesondere Auth-E-Mails, Session-Erneuerung, tatsächliche Storage-Regeln und gleichzeitige Gebote auf dem gehosteten System prüfen.

Noch offen: Moderation/Meldungen, automatische Text-/Bildprüfung, integrierte Zahlungen, E-Mail-Benachrichtigungen, Accountlöschung, Datenschutz-/Nutzungsinformationen für den tatsächlichen Betreiber und Backup-/Wiederherstellungsablauf. Verwaiste Uploads werden noch nicht automatisch gelöscht. Die Datenbank erzwingt maximal 40 Uploadreservierungen pro Nutzer und 24 Stunden; Storage akzeptiert nur reservierte Bildpfade innerhalb von zehn Minuten. Auch fehlgeschlagene Uploads zählen zur Quote. Direkte Tabellenzugriffe sind gesperrt. Für öffentliche Registrierung zusätzlichen Missbrauchsschutz einrichten. Daher zuerst mit einem kleinen geschlossenen Testkreis arbeiten.

## Herkunft

Das Desktop-Original wurde nur gelesen. Die bisherige Cloudflare-/Sites-Statusbeschreibung und die bestehende Hosting-Identität liegen in `archive/`. Diese Version verwendet Vercel, daher wird keine neue Site registriert. Bei einer späteren Rückkehr zu Sites die archivierte Projekt-ID wiederverwenden.

## Offizielle Dokumentation

- [Supabase-GitHub-Integration](https://supabase.com/docs/guides/deployment/branching/github-integration)
- [Supabase-E-Mail-OTP](https://supabase.com/docs/guides/auth/auth-email-passwordless)
- [Supabase-Zugriffsregeln / RLS](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Supabase-Free-Grenzen](https://supabase.com/docs/guides/platform/billing-on-supabase)
- [Vercel Hobby](https://vercel.com/docs/plans/hobby)
