# Produktfotos

Ein bis fünf eigene JPG-, PNG- oder WebP-Fotos je Inserat, maximal 4 MB je Foto. Mehrere Dateien können gemeinsam ausgewählt werden; die App lädt sie einzeln hoch. Bereits erfolgreiche Uploads bleiben bei einem späteren Uploadfehler erhalten. Das erste Foto ist das Titelbild. Reihenfolge und Titelbild können im Formular geändert und einzelne Fotos entfernt werden.

Fotos sind in Supabase privat gespeichert. PostgreSQL prüft Eigentum und vorhandene Storage-Datei für jedes Foto. Unveröffentlichte Fotos sind nur für ihren Eigentümer lesbar. Öffentlich zugänglich sind Fotos, die an ein nicht gesperrtes Inserat gebunden sind. Meldungen bewahren den damaligen Foto-Stand für die Moderation. Entfernen löst die Zuordnung zum Inserat; die Datei wird dabei nicht gelöscht. Noch keine automatische Bereinigung verwaister Uploads.

Galerieänderungen sind nur bei laufenden Inseraten vor dem ersten Gebot erlaubt. Datenbanksperre und Versionsprüfung schützen vor gleichzeitigen Geboten und veralteten Formularen. Einzelfoto-Clients bleiben kompatibel; bestehende Fotos wurden als Galerie mit einem Eintrag übernommen.

Das bestehende Tageslimit bleibt bei 40 Uploadreservierungen je Konto und 24 Stunden, einschliesslich fehlgeschlagener Uploads. Fünf Fotos verbrauchen fünf Reservierungen. Neue Galerie-Migration nur einmal anwenden.

Vor Veröffentlichung mit zwei echten Konten prüfen: gemeinsam mehrere Fotos hochladen, Vorschauen und Titelbild ändern, speichern/neuladen, Galerie als Käufer ansehen, vor dem ersten Gebot bearbeiten, danach Änderung ablehnen. Testartikel ausschliesslich als technische Tests ohne echte Zahlung oder Lieferung kennzeichnen.
