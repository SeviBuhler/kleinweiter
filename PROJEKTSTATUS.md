# kleinweiter – Stand 1. Oktober 2026

Das Desktop-Projekt wurde nach `outputs/kleinweiter` übernommen und auf Next.js 16, Vercel und Supabase migriert. Bestehendes Design und Kernabläufe wurden weiterverwendet. Cloudflare D1/R2, Vinext und ChatGPT-Header-Anmeldung wurden durch PostgreSQL-Funktionen, Supabase Auth und Storage ersetzt. Fremde Inspirationsfotos wurden durch eigene SVG-Illustrationen ersetzt.

Installation und Next.js-Produktionsbuild waren unter Windows erfolgreich; der frühere `spawn EPERM`-Blocker trat bei diesem Projektaufbau nicht auf. SQL-Migration und Berechtigungs-/Handelstests mit zwei simulierten Identitäten in einer isolierten PostgreSQL-Engine waren erfolgreich. Die Datenbankfunktionen sind echte PostgreSQL-Funktionen; Tests verwenden keine nachgebaute Handelslogik.

Auf Wunsch des Nutzers endet dieser Auftrag bei einem lokalen Git-Repository. Kein GitHub-Push, keine Vercel-Veröffentlichung, kein Supabase-Projekt und keine echten Nutzerkonten wurden angelegt. Der Nutzer pusht und verbindet die Dienste selbst.

Ohne Supabase-Variablen läuft eine Vorschau ohne echte Inserate. Noch nicht für echte Verkäufe freigegeben. README enthält Einrichtung und Hostinghinweise; TESTPLAN enthält verbleibende Integrationsprüfungen. Automatische Moderation, integrierte Zahlung und vollständiger öffentlicher Betriebsumfang fehlen noch.

Die bestehende Sites-Identität ist in `archive/hosting-sites.json` erhalten, wird bei Vercel nicht verwendet. Das Desktop-Original blieb unangetastet.
