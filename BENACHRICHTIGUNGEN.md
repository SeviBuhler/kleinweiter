# Benachrichtigungen

Angemeldete Nutzer sehen eine Glocke im Kopfbereich. Der Zähler zeigt ungelesene Nachrichten; die Liste zeigt bis zu 100 Nachrichten, ungelesene zuerst. Einzelne oder alle Nachrichten können als gelesen markiert werden. Öffnen der Liste allein markiert nichts. «Angebot im Konto ansehen» öffnet den betreffenden Kontoeintrag; aktive Angebote können von dort geöffnet werden. Die Kontoübersicht ist derzeit auf die jüngsten 250 beteiligten Angebote begrenzt.

## Ereignisse

- Überboten: vorheriger Höchstbieter, wenn ein anderes Mitglied bietet oder sofort kauft. Eigenes Erhöhen erzeugt keine Nachricht.
- Sofortkauf bestätigt: Käufer, zusätzlich Verkaufsnachricht an Verkäufer.
- Auktionsende mit Gebot: Gewinner und Verkäufer.
- Auktionsende ohne Gebot: Verkäufer.
- Moderationssperre: Verkäufer und alle bisherigen Bieter, einschliesslich Begründung. Pro Person eine Sperrnachricht.

Nachrichten entstehen durch einen PostgreSQL-Trigger auf Angebotsänderungen in derselben Transaktion. Fehlgeschlagene Handelsaktionen erzeugen keine Nachricht. Eindeutigkeit je Empfänger, Angebot, Ereignis und Revision verhindert doppelte Speicherung. Die Migration spielt keine früheren Ereignisse nach.

## Sicherheit und Betrieb

`notifications` ist privat, mit RLS und ohne direkte Rechte für anon/authenticated. Schreiben erfolgt ausschliesslich durch den Trigger. `notification_feed()` und `notification_read(uuid)` verlangen ein bestätigtes Konto und filtern auf dessen ID. Niemand kann Nachrichten für fremde Empfänger erstellen oder markieren. Kein administrativer Schlüssel im Frontend; API-Schreibaufrufe prüfen die Herkunft.

Die Glocke lädt beim Seitenaufruf und danach etwa alle 30 Sekunden in sichtbaren Tabs, zusätzlich bei Rückkehr in den Tab und nach eigenen Handelsaktionen. Nachrichten enthalten keine E-Mail-Adressen. Auf Moderationsseiten werden Nachrichten erst bei Rückkehr zum Marktplatz angezeigt.

Der Auktionsabschluss wird weiterhin beim nächsten Markt-/Benachrichtigungsabruf vorgenommen. Ohne Seitenbesuch erfolgt noch kein Hintergrundabschluss; ein Scheduler ist ein separater nächster Schritt. Keine E-Mails, Browser-Pushs oder zusätzliche Versanddienst-Anbindung. Nachrichten bleiben gespeichert; automatische Aufbewahrungsfristen und Accountlöschung fehlen noch.

## Prüfung

`npm test` führt echte Migrationen in PGlite aus. Die Benachrichtigungsprüfung deckt Empfänger, Fremdzugriff, Eigengebote, Kauf, Ablauf, Sperren, Lesen und Duplikate ab. `scripts/verify-notifications.sql` prüft die zentralen Nachrichtenabläufe in Supabase mit vollständigem Rollback. Produktionsbuild prüft die API und TypeScript.
