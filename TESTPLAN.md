# Pilotprüfung nach Anbindung

Noch nicht mit echten Konten durchgeführt. Zwei erwachsene Tester A (Verkäufer) und B (Käufer), getrennte Browserprofile oder ein privates Fenster verwenden. Ausschliesslich Testartikel ohne reale Kaufabsicht; danach Supabase-Testprojekt zurücksetzen oder Testdaten gezielt administrativ entfernen. Die SQL-Migration niemals einfach nochmals ausführen.

1. A und B erhalten je einen E-Mail-Code, melden sich an, laden die Seite neu und melden sich wieder ab. Abgelaufene/falsche Codes werden abgelehnt. Sitzungserneuerung nach Tokenablauf prüfen.
2. A lädt eigenes JPG/PNG/WebP bis 4 MB hoch. Grössere Bilder, HTML und SVG werden abgelehnt. B kann As unveröffentlichtes Foto nicht ansehen oder verwenden.
3. A stellt ein Inserat ein, z. B. Alterswelt 3–6, Start CHF 10, Sofortkauf CHF 30. Suche, Kategorie, mobile Darstellung und Anzeigename prüfen.
4. A darf nicht selbst bieten. B muss das Gebot ausdrücklich bestätigen. CHF 9.99 scheitert; CHF 10 ist als Erstgebot zulässig; danach liegt das Minimum bei CHF 11. Ein Gebot ab CHF 30 verweist auf Sofortkauf.
5. Vor Verkauf sind in beiden Kontoansichten keine Kontaktadressen sichtbar. Öffentliche API-Antworten enthalten weder E-Mail noch Bieter-ID. Ein drittes fremdes Konto sieht nach Verkauf ebenfalls keine Kontakte.
6. B kauft für CHF 30. Ein zweiter Kauf scheitert. A und B sehen im Konto jeweils die Kontakt-E-Mail des Gegenübers. Es wird keine Zahlung ausgelöst.
7. Zweites Inserat ohne Sofortkauf: B bietet, Endzeit im **Testprojekt** administrativ kurz vorverlegen und bis zum Ablauf warten. Weiteres Gebot scheitert; nächster Abruf setzt Status verkauft. Ohne Gebot wird ein abgelaufenes Inserat als ohne Gebot beendet angezeigt.
8. Zwei Browserfenster senden dasselbe Mindestgebot möglichst gleichzeitig. Genau eines darf angenommen werden. Zwei gleichzeitige Sofortkäufe dürfen nur einen Verkauf ergeben. Audit in Supabase: `listings.price`, `bid_count`, `bidder`, `status` und zugehörige `bids` stimmen überein. Tests auch knapp an der Endzeit durchführen.
9. Unangemeldete Schreibanfrage ergibt 401, fremder Origin 403. Direktes Schreiben in `listings`, `profiles` und `bids` über den öffentlichen Supabase-Key wird verweigert. Auch mit authentifiziertem Käufer-Token dürfen Preise/Eigentümer nicht direkt geändert werden.
10. Unbestätigte E-Mail darf keine Handelsaktion ausführen. Registrierung ist für den geschlossenen Pilotkreis im Dashboard eingeschränkt. Speicherverbrauch, Versandlimits und Fehlerlogs prüfen.

Automatisiert geprüft: SQL-Migration, RLS und Datenbankrechte, Pflichtfelder, Kategorien/Alter, Bilderbesitz, eigene Gebote, Mindestgebot, Kaufbestätigung, Sofortkauf, erneuter Kauf, Kontaktschutz und Ablauf mit simulierten Identitäten in PGlite. Parallelität und echte Auth-/Storage-Dienste bleiben Integrationstests.
