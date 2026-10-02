# Moderation in kleinweiter

Die Betreiberseite liegt unter `/moderation`. Nur ausdrücklich in `public.moderators` freigeschaltete Supabase-Nutzer erhalten Zugriff. Normale Konten können keine Rollen vergeben, Meldungen lesen oder Moderationsaktionen ausführen. Die Rollenprüfung erfolgt auf der Seite, an der API und erneut in jeder Datenbankfunktion. Es gibt keinen Admin-Schlüssel im Browser.

## Meldung prüfen

Die Übersicht zeigt bis zu 200 Meldungen, offene zuerst. Vergleiche die Meldung und den gespeicherten ursprünglichen Inseratstand mit dem aktuellen Angebot. Beide Produktfotos sind verfügbar. Angaben zur meldenden Person werden in der Oberfläche nicht angezeigt.

Drei Entscheidungen stehen zur Verfügung:

- **Unbegründet verwerfen:** Meldung abschliessen, Angebot unverändert lassen.
- **Geprüft, beibehalten:** Prüfung dokumentieren, Angebot unverändert lassen.
- **Inserat sperren:** Laufende Auktion stoppen und aus der öffentlichen Suche entfernen. Neue Gebote und Sofortkauf sind gesperrt. Auch mit vorhandenen Geboten kann die Moderation eine laufende Auktion stoppen. Preis und Gebotshistorie bleiben erhalten.

Jede Entscheidung braucht eine Begründung von 10 bis 1000 Zeichen und eine Bestätigung. Bei einer Sperre sehen Verkäufer und bisherige Bieter die Begründung in ihrer Kontoübersicht. Keine Identität der meldenden Person oder sensible persönliche Angaben in diese Begründung aufnehmen.

Sperren betreffen ausschliesslich noch laufende Auktionen. Bereits verkaufte oder zeitlich abgelaufene Angebote werden damit nicht nachträglich storniert. Ein seit dem Öffnen des Formulars geändertes Angebot kann erst nach erneuter Prüfung gesperrt werden. Die Datenbank nutzt dieselbe Inseratsperre wie Gebote und Sofortkauf.

Es gibt keine Wiederfreigabe, Rückzahlung oder E-Mail-Benachrichtigung in dieser Version. Die Sperre wird im Konto sichtbar. Zahlung und Übergabe bleiben direkte Absprachen; bei bereits entstandenen Verpflichtungen oder Zahlungen muss der Betreiber die Beteiligten gesondert kontaktieren und den Fall klären.

## Betreiberzugang verwalten

Nur im Supabase SQL Editor als Datenbankbetreiber, nach Prüfung der konkreten Nutzer-ID in Authentication → Users:

```sql
-- Beispiel-ID ersetzen; nie anhand veränderbarer user_metadata freischalten.
insert into public.moderators(id)
values ('00000000-0000-0000-0000-000000000000'::uuid);
```

Entzug des Zugangs (gilt auch für bereits angemeldete Sitzungen beim nächsten Zugriff):

```sql
delete from public.moderators
where id = '00000000-0000-0000-0000-000000000000'::uuid;
```

Betreiberrechte werden nicht automatisch aus E-Mail-Adressen, Anzeigenamen oder Profilangaben abgeleitet. Das zweite Testkonto erhält keine Betreiberrechte.

## Protokoll und bisheriger SQL-Weg

`moderation_events` speichert Moderator, Meldung, Inserat, Entscheidung, Begründung, Gebotszahl, Preis und Zeitpunkt. App-Nutzer haben keine direkten Tabellenrechte. In der Oberfläche abgeschlossene Meldungen können nicht erneut entschieden werden. Die bisherige `review_listing_report`-Funktion bleibt ausschliesslich für den Datenbankbetreiber verfügbar.

Bei vielen offenen Meldungen ist später eine paginierte Warteschlange nötig. Ebenfalls offen: Benachrichtigungen, gesonderter Stornierungsablauf für abgeschlossene Verkäufe, Wiederfreigabe, Aufbewahrungs-/Löschregeln und regelmässige Kontrolle der Betreiberzugänge.
