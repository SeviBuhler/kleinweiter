# Automatischer Auktionsabschluss

Supabase pg_cron startet `public.settle_due_auctions()` jede Minute. Ein Websitebesuch oder ein Vercel-Cron ist dafür nicht erforderlich. Die Datenbank muss erreichbar und in Betrieb sein; bei Ausfall oder Pausierung erfolgt der Abschluss nach Wiederaufnahme. Die Endzeit selbst bleibt unverändert: Nach ihr werden keine Gebote mehr angenommen.

Nur aktive Angebote mit erreichter Endzeit werden bearbeitet. Mit Höchstbieter entsteht ein Verkauf zum gespeicherten Gebot samt festen Versandbedingungen; ohne Gebot wird das Angebot beendet. Bestehende Trigger legen Kaufablauf und Benachrichtigungen in derselben Transaktion an. Wiederholte Aufrufe erzeugen keine weiteren Verkäufe oder Nachrichten. Zurückgezogene, gesperrte und bereits verkaufte Angebote werden nicht verändert.

Je Lauf maximal 500 Angebote. Bereits durch einen anderen Vorgang gesperrte Datensätze werden übersprungen und beim nächsten Lauf erneut geprüft. Im normalen Pilotbetrieb entsteht der Abschluss innerhalb ungefähr einer Minute; bei Rückstau, Sperren oder Betriebsstörungen kann es länger dauern. Der bisherige Abschluss beim Markt-/Nachrichtenabruf bleibt als zusätzliche Absicherung bestehen.

Die Funktion besitzt einen festen leeren Suchpfad und ist weder für `anon` noch `authenticated` aufrufbar. Der Job läuft als Datenbankbetreiber. Keine administrativen Schlüssel in Vercel oder im Browser erforderlich.

## Einrichtung und Betrieb

Zuerst die Migration `20261003000200_auction_settlement.sql` einmal anwenden. Danach als `postgres` das separate Betriebsskript `scripts/setup-auction-cron.sql` ausführen. Es aktiviert pg_cron und den benannten Job `kleinweiter-auction-settlement`; Wiederholung aktualisiert denselben Job. Eine Datenbankmigration allein aktiviert den Zeitplan nicht.

Im Supabase-Dashboard unter Integrations → Cron die Aktivierung und History prüfen. Alternativ:

```sql
select j.jobname,j.active,r.status,r.return_message,r.start_time,r.end_time
from cron.job j
left join lateral (
 select * from cron.job_run_details d where d.jobid=j.jobid
 order by d.start_time desc limit 10
) r on true
where j.jobname='kleinweiter-auction-settlement';
```

Bei Fehlern Ursache beheben und den nächsten Lauf kontrollieren. Zum vorübergehenden Pausieren nur diesen Job in der Cron-Oberfläche deaktivieren. Die Erweiterung nicht entfernen: Das würde alle Cron-Jobs löschen. Laufprotokolle wachsen mit der Zeit; deren Aufbewahrung später bewusst festlegen. Es gibt noch keine externe Störungsbenachrichtigung.

Prüfung: Automatische Datenbanktests für Gewinner, Ende ohne Gebot, unveränderte zukünftige Angebote, genau einen Kaufablauf und Nachrichten, verweigerten öffentlichen Funktionszugriff. `scripts/verify-auction-settlement.sql` prüft dieselben Kernregeln im echten Supabase-Projekt mit vollständigem Rollback. Ein erfolgreicher Eintrag in der Cron-History bestätigt zusätzlich, dass der Scheduler selbst arbeitet.

Offizielle Anleitung: https://supabase.com/docs/guides/cron/quickstart
