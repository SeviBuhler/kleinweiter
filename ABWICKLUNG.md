# Abwicklung nach dem Kauf

Im Konto unter «Käufe abwickeln» erscheinen verkaufte Artikel, an denen du als Käufer oder Verkäufer beteiligt bist. Der feste Verkaufsstand enthält Artikelpreis, Versandkosten und vereinbarte Zahlung/Übergabe. Der Gesamtbetrag wird angezeigt. Die Kontaktdaten der anderen Person sind nur den Beteiligten zugänglich. Nachrichtenlinks zu verkauften Artikeln öffnen diese Übersicht direkt.

## Bestätigungen

- Käufer: «Zahlung veranlasst» und «Artikel erhalten».
- Verkäufer: «Zahlung erhalten» und «Versandt / übergeben».

Die Angaben sind Erklärungen der Beteiligten, keine Bankprüfung. Sie können unabhängig voneinander erfolgen, etwa bei Barzahlung und Abholung. Vor dem Speichern ist eine ausdrückliche Bestätigung erforderlich. Bestätigungen bleiben mit Zeitstempel im Verlauf; sie lassen sich hier nicht zurücknehmen. Alle vier Bestätigungen und keine offene Problemmeldung ergeben «Abgeschlossen».

## Probleme

Jede beteiligte Person kann einmal pro Verkauf ein Problem melden. Grund und Beschreibung sind für beide Beteiligte und ausdrücklich freigeschalteten Support sichtbar. Keine sensiblen Angaben eingeben. Die meldende Person kann ihr eigenes offenes Problem mit Begründung als gelöst bestätigen. Die andere Person kann es nicht schliessen. Weitere Meldungen desselben Kontos zu diesem Verkauf sind im kleinen Startumfang nicht vorgesehen.

Probleme können auch nach einem bereits bestätigten Abschluss gemeldet werden. «Problem offen» hat dann Vorrang; der frühere Abschlusszeitpunkt bleibt nachvollziehbar. Kauf, Preis, Gebote und Bestätigungen werden durch eine Meldung oder Prüfung nicht geändert. Keine automatische Stornierung, Rückzahlung oder Käuferschutzentscheidung.

## Support

Der Datenbankbetreiber kann bestehende Moderatoren zusätzlich mit `order_support=true` freischalten. Standard ist false. Der Zugriff muss ausdrücklich bestätigt werden, weil private Verkaufsprobleme sichtbar werden. Rollen lassen sich nicht über die App vergeben. Ein zusätzlich freigeschalteter Betreiber sieht `/moderation/sales` und kann offene Probleme begründet abschliessen. Eigene Verkäufe kann er nicht als Support prüfen; die meldende Person kann ihr eigenes Problem weiterhin selbst lösen. Ohne zweiten Support-Betreiber bleibt eine fremde Meldung zu seinem eigenen Verkauf offen.

Beispiel für eine bestätigte Freischaltung oder Widerruf (verifizierte UUID einsetzen):

```sql
update public.moderators set order_support=true where id='VERIFIED-USER-UUID';
-- Widerruf:
update public.moderators set order_support=false where id='VERIFIED-USER-UUID';
```

## Technik und Grenzen

`orders`, `order_issues` und `order_events` haben RLS und keine direkten App-Tabellenrechte. Ein Trigger erstellt beim Verkauf einen festen Datensatz. Historische Verkäufe erhalten bei der Migration einen offenen Ablauf; Zahlung oder Lieferung werden nicht angenommen. PostgreSQL-Funktionen prüfen bestätigte Identität, Beteiligung, Zuständigkeit und Revision unter einer Datensatzsperre. Bestätigungen, Verlauf und Benachrichtigung werden atomar geschrieben.

Die Übersicht zeigt bis zu 250 eigene Verkäufe; der Support bis zu 200 Verkäufe mit Problemen. Die Seite aktualisiert auf Wunsch, nach eigenen Aktionen und beim erneuten Öffnen. Veraltete Formulare werden abgelehnt. Kein Chat, keine Datei-Belege, keine automatische Erinnerungs-E-Mail. Auktionsabschluss erfolgt weiterhin beim nächsten Markt-/Benachrichtigungsabruf.

Tests: `tests/orders.test.mjs` prüft echte Migrationen und vier Identitäten. `scripts/verify-orders.sql` prüft zentrale Abläufe im Live-Projekt mit vollständigem Rollback. Der Vercel-Test wird in `PROJEKTSTATUS.md` dokumentiert.
