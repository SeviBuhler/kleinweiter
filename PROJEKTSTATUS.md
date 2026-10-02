# kleinweiter – Stand 2. Oktober 2026

Next.js/React/TypeScript, Vercel und Supabase ersetzen den ursprünglichen Vinext-/Cloudflare-Aufbau. Das Desktop-Original blieb unverändert. Eigene SVG-Illustrationen ersetzen fremde Inspirationsbilder.

## Betrieb

- GitHub: https://github.com/SeviBuhler/kleinweiter.git. Der Nutzer pusht lokale Commits selbst.
- Website: https://kleinweiter.vercel.app. Supabase- und Google-Login-Variablen sind in Vercel gesetzt; Google-Anmeldung ist veröffentlicht.
- Supabase: `bhogyeublnutiyfjwmou`. Migrationen `20261001000100`, `20261001000200`, `20261002000100`, `20261002000200` `20261002000300` und `20261002000400` sind angewandt und registriert.
- Google-OAuth-Projekt: `kleinweiter-sevi-20261001`. Google-Anmeldung funktioniert mit beiden Testkonten. Freigabe für weitere Tester hängt vom Google-Audience-Status ab.
- Keine Zugangsdaten im Git. Lokale Umgebungsdatei ist ignoriert. Kein service_role-Key in der App.

## Funktionen und Sicherheit

Alterswelten, Suche, Kategorien, CHF-Auktionen, Sofortkauf, eigene Fotos, Anzeigenamen und Kontoseiten sind vorhanden. Zahlung und Übergabe vereinbaren die Beteiligten direkt. Kontakte werden erst nach Kauf/Auktionsabschluss an Verkäufer und Gewinner freigegeben.

RLS und entzogene direkte Tabellenrechte schützen die Daten. Schreiben erfolgt durch geprüfte PostgreSQL-Funktionen. Privat gespeicherte Rasterbilder sind auf 4 MB begrenzt. Anmeldung verwendet Supabase Auth und einen serverseitigen PKCE-Callback.

Neue Inseratverwaltung: eigene aktive Inserate lassen sich vor dem ersten Gebot bearbeiten oder zurückziehen. Preis und Auktionsende bleiben beim Bearbeiten unverändert. Zurückgezogene Inserate bleiben im Konto und verschwinden aus der Suche. Datenbanksperren und Versionsprüfung verhindern Änderungen bei inzwischen eingegangenen Geboten oder veralteten Formularen. Die neue Oberfläche ist mit Commit `120d784` auf GitHub und Vercel veröffentlicht.

## Prüfung

Installation, Produktionsbuild und vier automatische Tests erfolgreich. SQL-Tests prüfen mit zwei Identitäten Eigentum, Bearbeiten, veraltete Änderungen, Zurückziehen, Gebotssperren, Kauf und Kontaktrechte. Live-Supabase-Tests verwenden eine Transaktion mit vollständigem Rollback und bestanden ebenfalls.

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

Migration `20261002000400` ist angewandt und registriert. Vier automatische Tests und Produktionsbuild bestanden. Live-Supabase-Test mit synthetischen Identitäten und vollständigem Rollback prüfte Empfänger, Übergebot, Kauf, Verkäufernachricht, fremde Lesemarkierung und Duplikatvermeidung. Veröffentlichung und Browser-Test der neuen Oberfläche stehen noch aus. Auktionsende wird beim nächsten Markt-/Benachrichtigungsabruf festgestellt; ohne Abruf gibt es noch keinen zeitgesteuerten Abschluss. Anleitung: `BENACHRICHTIGUNGEN.md`.

## Vor breiterem Einsatz

Kleine geschlossene Testphase empfohlen. E-Mail-Benachrichtigungen, zeitgesteuerter Auktionsabschluss und Klärung abgeschlossener Verkäufe, Accountlöschung, Betriebs-/Datenschutzinformationen, Backups und Bereinigung verwaister Uploads fehlen. Automatische Inhaltsprüfung und integrierte Zahlungen sind nicht implementiert.
