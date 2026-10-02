# Meldungen prüfen

Angemeldete Nutzer können fremde aktive Inserate im Detaildialog melden. Ein Grund und eine Beschreibung von 10 bis 1000 Zeichen sind nötig. Es gilt eine Meldung je Konto und Inserat sowie höchstens zehn Meldungen innerhalb von 24 Stunden. Eigene, beendete oder zurückgezogene Angebote sind ausgeschlossen.

Meldungen sind keine öffentlichen Kommentare. Anonyme und angemeldete App-Nutzer haben keine direkten Lese- oder Schreibrechte auf `listing_reports`. Die Datenbankfunktion nimmt Meldungen entgegen und speichert den damaligen Inseratstand als Snapshot. Der Verkäufer sieht weder die Meldung noch die meldende Person.

## Für den Betreiber

Im Supabase SQL Editor, mit dem bestehenden Datenbank-Administrationszugang:

```sql
select id, listing, reason, details, snapshot, created
from public.listing_reports
where status = 'open'
order by created;
```

Prüfe Beschreibung und Snapshot. Nach Prüfung den Status mit der geschützten Funktion abschliessen; `reviewed` bedeutet geprüft, `dismissed` bedeutet als unbegründet verworfen. Ersetze die Beispiel-ID und dokumentiere die konkrete Entscheidung:

```sql
select public.review_listing_report(
  '00000000-0000-0000-0000-000000000000'::uuid,
  'dismissed',
  'Begründung der Entscheidung'
);
```

Die Funktion ist für App-Nutzer gesperrt. Kein Admin-Schlüssel gehört in die Website. Abgeschlossene Meldungen können mit dieser Funktion nicht nachträglich überschrieben werden.

**Wichtig:** Der Prüfstatus entfernt kein Inserat und storniert keine Auktion. Meldungen führen nicht automatisch zu einer Sperre. Eine administrative Sperr-/Stornierungsfunktion, Benachrichtigungen an Betroffene und eine eigene Moderationsoberfläche sind weitere Ausbauschritte. Bei laufenden Geboten keine Bedingungen direkt in der Tabelle ändern.

Meldungen können persönliche Angaben enthalten. Zugriff auf das Supabase-Projekt nur berechtigten Personen geben. Eine Aufbewahrungs-/Löschregel für Meldungen muss vor breiterem Betrieb festgelegt werden.
