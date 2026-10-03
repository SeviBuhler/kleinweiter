# kleinweiter – Stand 3. Oktober 2026

Next.js/React/TypeScript, Vercel und Supabase ersetzen den ursprünglichen Vinext-/Cloudflare-Aufbau. Das Desktop-Original blieb unverändert. Eigene SVG-Illustrationen ersetzen fremde Inspirationsbilder.

## Betrieb

- GitHub: https://github.com/SeviBuhler/kleinweiter.git. Der Nutzer pusht lokale Commits selbst.
- Website: https://kleinweiter.vercel.app. Supabase- und Google-Login-Variablen sind in Vercel gesetzt; Google-Anmeldung ist veröffentlicht.
- Supabase: `bhogyeublnutiyfjwmou`. Migrationen `20261001000100`, `20261001000200`, `20261002000100`, `20261002000200`, `20261002000300`, `20261002000400`, `20261002000500`, `20261003000100` und `20261003000200` sind angewandt und registriert.
- Google-OAuth-Projekt: `kleinweiter-sevi-20261001`. Google-Anmeldung funktioniert mit beiden Testkonten. Freigabe für weitere Tester hängt vom Google-Audience-Status ab.
- Keine Zugangsdaten im Git. Lokale Umgebungsdatei ist ignoriert. Kein service_role-Key in der App.

## Funktionen und Sicherheit

Alterswelten, Suche, Kategorien, CHF-Auktionen, Sofortkauf, eigene Fotos, Anzeigenamen und Kontoseiten sind vorhanden. Zahlung und Übergabe vereinbaren die Beteiligten direkt. Kontakte werden erst nach Kauf/Auktionsabschluss an Verkäufer und Gewinner freigegeben.

RLS und entzogene direkte Tabellenrechte schützen die Daten. Schreiben erfolgt durch geprüfte PostgreSQL-Funktionen. Privat gespeicherte Rasterbilder sind auf 4 MB begrenzt. Anmeldung verwendet Supabase Auth und einen serverseitigen PKCE-Callback.

Neue Inseratverwaltung: eigene aktive Inserate lassen sich vor dem ersten Gebot bearbeiten oder zurückziehen. Preis und Auktionsende bleiben beim Bearbeiten unverändert. Zurückgezogene Inserate bleiben im Konto und verschwinden aus der Suche. Datenbanksperren und Versionsprüfung verhindern Änderungen bei inzwischen eingegangenen Geboten oder veralteten Formularen. Die neue Oberfläche ist mit Commit `120d784` auf GitHub und Vercel veröffentlicht.

## Prüfung

Installation, Produktionsbuild und sechs automatische Tests erfolgreich. SQL-Tests prüfen mit mehreren Identitäten Eigentum, Bearbeiten, veraltete Änderungen, Zurückziehen, Gebotssperren, Kauf, Kontaktrechte und Galerien. Live-Supabase-Tests verwenden eine Transaktion mit vollständigem Rollback und bestanden ebenfalls.

Mit zwei echten Google-Konten wurden Anmeldung, Foto-Upload, Inseraterstellung und Eigentum geprüft. Ein ausdrücklich als Test markiertes Inserat erhielt ein gültiges Gebot; ein zu niedriges Gebot wurde abgelehnt. Der Sofortkauf wurde bestätigt und entfernte das Angebot aus der öffentlichen Suche. Es fand keine Zahlung statt. Kaufhistorie und gegenseitige Kontaktanzeige wurden auf beiden echten Kontoseiten bestätigt. Der Testartikel verbleibt als Verkaufshistorie. Ein zweiter klar markierter Testartikel wurde auf Vercel bearbeitet, nach Neuladen mit geändertem Titel geprüft und zurückgezogen. Abbrechen des Bestätigungsdialogs liess ihn aktiv. Nach Zurückziehen bleibt er im Konto sichtbar und fehlt im öffentlichen Feed (HTTP 200, leere Angebote).

Noch offen: gleichzeitige Handelsaktionen auf dem gehosteten System und Session-Erneuerung über längere Zeit. Datenbanksperren sind implementiert; die bisherigen Tests ersetzen keinen echten Paralleltest.

## Neue Meldefunktion

Angemeldete Nutzer können fremde aktive Inserate melden. Grund und Beschreibung sind erforderlich. Eine Meldung je Konto/Inserat und zehn pro 24 Stunden; keine direkten Tabellenrechte. Der damalige Inseratstand wird privat als Snapshot gespeichert. Explizit freigeschaltete Moderatoren dokumentieren Prüfergebnisse über `/moderation`. Eine Meldung allein lässt die Auktion aktiv; kein automatisches Sperren oder Stornieren. Anleitung: `MODERATION.md`.

Die Datenbankmigration ist angewandt. Automatische Rechte-/Funktionstests und Produktionsbuild bestanden. Commit `546f64d` ist auf GitHub und Vercel veröffentlicht. Mit zwei echten Google-Konten wurden Testinserat, Meldespeicherung, Bestätigung und Ablehnung einer Doppelmeldung geprüft. Supabase zeigte genau eine offene Meldung mit passendem Snapshot; sie wurde per Funktion als technischer Test abgeschlossen (`dismissed`). Die Meldung liess Preis, Gebote und aktiven Angebotsstatus unverändert. Der Verkäufer zog den Testartikel anschliessend zurück.

## Neue Moderationsoberfläche

`/moderation` mit expliziter Datenbankrolle, Meldungs-/Inseratvergleich, Prüfentscheidungen und Sperre laufender Auktionen. Eine Sperre bleibt für Verkäufer und Bieter mit Begründung sichtbar; sie sperrt Gebote und Sofortkauf und verbirgt das Produktfoto vor öffentlichem Zugriff, soweit es nicht auch an ein anderes freigegebenes Inserat gebunden ist. Keine Wiederfreigabe und keine nachträgliche Stornierung abgeschlossener Käufe. Jede Entscheidung wird privat protokolliert. Rollen können nicht über die App vergeben werden.

Automatische Datenbanktests mit drei Identitäten, Live-Supabase-Tests mit vollständigem Rollback und Produktionsbuild bestanden. Migration ist angewandt. Commit `e03d579` ist auf GitHub und Vercel veröffentlicht. Nach ausdrücklicher Zustimmung wurde ausschliesslich das verifizierte Hauptkonto `sevibuhler@gmail.com` als Betreiber freigeschaltet. Das zweite Google-Konto erhält keinen Moderationszugang; `/moderation` liefert dort 404. Anonyme API-Aufrufe werden mit 403 abgewiesen.

Mit beiden echten Google-Konten wurde eine ausdrücklich technische Testauktion erstellt, mit einem Testgebot versehen, gemeldet und durch das Hauptkonto gesperrt. Sie verschwindet aus dem öffentlichen Feed; ihr privates Foto liefert anonym 404. Ein bereits vor der Sperre geöffneter Sofortkaufdialog wurde beim Absenden abgewiesen. Preis und Gebot bleiben als Historie erhalten. Käufer und Verkäufer sehen in ihrem Konto den Status «Von Moderation gesperrt» und die gespeicherte Begründung. Die geschlossene Meldung erscheint im Moderationsarchiv. Keine Zahlung, Lieferung oder reale Anschuldigung erfolgte; die gesperrte Testauktion bleibt zur Nachvollziehbarkeit gespeichert.

## Benachrichtigungen in der WebApp

Private Nachrichten bei Übergeboten, Sofortkäufen, Auktionsabschluss (Gewinn/Verkauf oder ohne Gebot) und Moderationssperren. Glocke mit Ungelesen-Zähler, Einzel-/Sammelmarkierung und Angebotslink zum betroffenen Kontoeintrag. RLS und entzogene Tabellenrechte; nur bestätigte Konten können ihre eigenen Nachrichten per Funktion lesen und markieren. Transaktionaler Trigger schreibt Ereignisse gemeinsam mit der Angebotsänderung. Keine rückwirkenden Nachrichten für Altbestände, keine E-Mails oder Browser-Pushs.

Migration `20261002000400` ist angewandt und registriert. Fünf automatische Tests und Produktionsbuild bestanden. Live-Supabase-Test mit synthetischen Identitäten und vollständigem Rollback prüfte Empfänger, Übergebot, Kauf, Verkäufernachricht, fremde Lesemarkierung und Duplikatvermeidung. Commit `f1f88df` ist auf GitHub und Vercel veröffentlicht. Mit beiden echten Google-Konten wurde der ausdrücklich technische Testartikel «TEST – Kaufnachricht – kein Verkaufsangebot» erstellt und per Sofortkauf abgeschlossen. Käufer und Verkäufer erhalten je eine eigene Nachricht. Ungelesen-Zähler, Einzel-/Sammelmarkierung und Angebotslinks in beide Kontoseiten funktionieren; der gelesene Zustand bleibt nach Navigation bestehen. Es erfolgten keine Zahlung oder Übergabe. Der Testverkauf bleibt als Historie gespeichert. Anonyme API-Aufrufe liefern 401. Auktionsgewinn und Sperrnachrichten wurden in den automatischen Datenbanktests geprüft; dafür wurde keine weitere dauerhafte Live-Testauktion erstellt. Seit dem 3. Oktober erfolgt der Abschluss zusätzlich zeitgesteuert; siehe Abschnitt Automatischer Auktionsabschluss. Anleitung: `BENACHRICHTIGUNGEN.md`.

## Abwicklung nach Verkauf

Fester Verkaufsstand für Preis, Versandkosten und Übergabebedingungen, eigene Käufer-/Verkäuferbestätigungen, Verlauf und Nachrichten. Nur Beteiligte können ihren Verkauf sehen und ihre zuständigen Schritte bestätigen. Alle vier Bestätigungen und keine offene Problemmeldung ergeben einen abgeschlossenen Ablauf. Problemmeldungen sind für beide Beteiligte sichtbar; die meldende Person kann ihr eigenes Problem begründet lösen. Keine automatische Bankprüfung, Stornierung oder Rückzahlung. Anleitung: `ABWICKLUNG.md`.

Migration `20261002000500` ist angewandt und registriert. Bestehende Verkäufe erhalten offene Abläufe, ohne Zahlung oder Lieferung anzunehmen. Separater Support-Zugriff ist standardmässig ausgeschaltet und benötigt eine ausdrückliche Freischaltung. Support kann Probleme zu eigenen Verkäufen nicht selbst prüfen. Fünf automatische Tests mit bis zu vier Identitäten und Produktionsbuild bestanden. Live-Supabase-Tests mit vollständigem Rollback bestanden für festen Verkaufsstand, Rollen, veraltete Formulare, Problem-/Abschlussregeln, separate Support-Rechte und Nachrichten.

Mit Commit `86efe02` auf GitHub und Vercel veröffentlicht. Am 3. Oktober mit beiden echten Google-Testkonten am vorhandenen Testverkauf `bd287344-820b-49f1-88a7-eab48dad2bb9` geprüft: fester Gesamtpreis CHF 30, gegenseitiger Kontakt, getrennte Bestätigungsschritte für Käufer und Verkäufer, Speicherung aller vier simulierten Schritte, Problemmeldung und Lösung durch die meldende Person. Mit allen vier Bestätigungen bleibt ein offenes Problem offen; nach dessen Lösung erscheint «Abgeschlossen» in beiden Konten. Die Lösung enthält ausdrücklich den Hinweis auf simulierte Bestätigungen ohne echte Zahlung oder Übergabe. Neue Nachrichten entstehen und ihr Angebotslink öffnet direkt die Abwicklung. Anonymer Zugriff auf `/api/orders` liefert 401, auf `/api/order-support` 403. Separater Support-Zugriff wurde nicht freigeschaltet; seine Oberfläche wurde daher nicht mit einem echten berechtigten Konto geprüft.

## Mehrere Produktfotos

Bis zu fünf eigene Rasterfotos je Inserat, einzeln oder gemeinsam ausgewählt. Das erste Foto ist das Titelbild; im Formular sind Reihenfolge, Titelbild und Entfernen möglich. Produktdetails und Moderation zeigen eine Galerie mit Pfeilen, Zähler und Vorschaubildern. Bestehende Einzelfotos wurden übernommen. Nach dem ersten Gebot sind sämtliche Fotoänderungen in PostgreSQL gesperrt. Meldungen behalten alle damaligen Foto-IDs; entfernte Fotos bleiben für deren Prüfung zugänglich.

Migration `20261003000100` ist angewandt und registriert. Sechs automatische Tests und Produktionsbuild bestanden. Der Live-Supabase-Test prüfte mehrere Fotos, öffentliche Anzeige, Reihenfolge/Titelbild, fremdes Eigentum, Gebotssperre und gesperrte interne Funktionen mit vollständigem Rollback. Commit `86efe02` ist auf GitHub und Vercel veröffentlicht. Zwei eigene PNG-Testbilder wurden gemeinsam hochgeladen, Titelbild und Reihenfolge geändert, gespeichert und nach Neuladen mit dem Käuferkonto vollständig geladen und durchgeblättert. Entfernen eines Fotos wurde gespeichert und nach Neuladen bestätigt. Der technische Testartikel `8ccd06ac-ac1e-4c53-9351-5e7ccad64ee5` wurde danach zurückgezogen; der öffentliche Feed der Alterswelt 3–6 ist wieder leer. Fünf Fotos, Grenzwerte, Meldungssnapshots und die Fotosperre nach Geboten wurden automatisiert und in SQL geprüft; dafür wurde keine weitere dauerhafte Live-Testauktion angelegt. Die Moderationsgalerie wurde noch nicht separat im Browser geprüft.

## Automatischer Auktionsabschluss

Migration `20261003000200` ist angewandt und registriert. Der Supabase-Job `kleinweiter-auction-settlement` ist aktiv und startet jede Minute die private Funktion `settle_due_auctions()`. Maximal 500 fällige aktive Inserate je Lauf, mit Zeilensperren und SKIP LOCKED. Vorhandene Trigger erzeugen genau einen Kaufablauf sowie Gewinner-/Verkäufernachrichten; ohne Gebot entsteht nur die Ende-Nachricht. Öffentliche Rollen dürfen die Scheduler-Funktion nicht aufrufen. Markt- und Nachrichtenabrufe behalten ihren bisherigen Abschluss als Absicherung.

Sechs automatische Tests und Produktionsbuild bestanden. Live-Supabase-Test mit vollständigem Rollback bestand für Gewinn, Ablauf ohne Gebot, zukünftiges Inserat, festen Versandstand, Duplikatvermeidung und Funktionsrechte. Zwei tatsächlich zeitgesteuerte Läufe am 3. Oktober um 05:09 und 05:10 UTC sind in `cron.job_run_details` als `succeeded` bestätigt. Dafür wurde keine dauerhafte echte Auktion verändert oder neue Kaufzusage abgegeben. Scheduler und Funktion sind bereits live; kein Vercel-Deployment erforderlich. Anleitung und Betriebsskript: `AUKTIONSABSCHLUSS.md` und `scripts/setup-auction-cron.sql`. Der Betriebsskript-Schritt muss bei einem neuen Projekt zusätzlich zur Migration ausgeführt werden. Laufprotokoll-Aufbewahrung und externe Störungsbenachrichtigung sind noch offen.

## Betreiber und Datenschutz

Öffentliche Seiten `/betreiber` und `/datenschutz` mit Links im globalen Fussbereich, auch auf der Anmeldung. Veröffentlicht werden ausschliesslich die freigegebenen Angaben Severin Bühler und sevi.buehler@outlook.com; keine private Postadresse. Die Datenschutzerklärung beschreibt die tatsächlichen Daten, Sichtbarkeit, Dienstleister, Auslandbearbeitung und noch fehlende automatische Löschung. Supabase-Projektregion Frankfurt (eu-central-1) wurde im Dashboard geprüft.

Produktionsbuild und lokale Darstellung sowie Navigation bestanden. Noch nicht auf GitHub/Vercel veröffentlicht: Push und Prüfung der veröffentlichten Seiten stehen aus. Offene Betriebsfragen zu Kontaktadresse, Dienstleisterverträgen und Löschfristen stehen in `BETREIBER-DATENSCHUTZ.md`.

## Vor breiterem Einsatz

Kleine geschlossene Testphase empfohlen. E-Mail-Benachrichtigungen und Stornierungen/Rückzahlungen, Accountlöschung, Nutzungsbedingungen, Backups und Bereinigung verwaister Uploads fehlen. Betreiber-/Datenschutzseiten sind lokal vorbereitet; postalische Kontaktadresse und weitere Betriebsfragen bleiben offen. Automatische Inhaltsprüfung und integrierte Zahlungen sind nicht implementiert.
