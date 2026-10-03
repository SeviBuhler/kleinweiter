import type { Metadata } from "next";
import InfoShell from "../info-shell";
import { operator } from "@/lib/operator";
export const metadata: Metadata = { title: "Datenschutz · kleinweiter" };
export default function PrivacyPage() {
  return (
    <InfoShell title="Datenschutz">
      <p className="info-lead">
        Hier erfährst du, welche Daten kleinweiter für Anmeldung, Inserate und
        Handel verwendet und wer sie sehen kann.
      </p>
      <p className="hint">
        Stand: 3. Oktober 2026 · für die aktuelle Testphase in der Schweiz
      </p>
      <section>
        <h2>1. Verantwortlich und erreichbar</h2>
        <p>
          Verantwortlich für die Datenbearbeitung ist {operator.name}, Betreiber
          von kleinweiter. Kontakt für Fragen, Auskunft, Berichtigung und
          Löschungsanfragen:{" "}
          <a href={"mailto:" + operator.email}>{operator.email}</a>. Die
          Plattform richtet sich an erwachsene Nutzer in der Schweiz;
          massgeblich ist das schweizerische Datenschutzrecht.
        </p>
      </section>
      <section>
        <h2>2. Welche Daten wir bearbeiten</h2>
        <div className="info-table">
          <table>
            <caption>Daten und ihre Verwendung</caption>
            <thead>
              <tr>
                <th scope="col">Daten</th>
                <th scope="col">Wofür?</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>
                  Kontokennung, E-Mail, Anmeldestatus und von Google
                  bereitgestellte Profildaten wie Name und gegebenenfalls
                  Profilbild; dein gewählter Anzeigename.
                </td>
                <td>
                  Konto anlegen, sicher anmelden, Konten zuordnen und deinen
                  Anzeigenamen anzeigen. Das Google-Passwort erhält kleinweiter
                  nicht.
                </td>
              </tr>
              <tr>
                <td>
                  Inserattext, bis zu fünf Produktfotos, Kinder-Alterswelt,
                  Kategorie, Zustand, Grössenangabe, Standort, Preise,
                  Versandkosten und Übergabebedingungen.
                </td>
                <td>
                  Inserate veröffentlichen, finden und anzeigen. Die Alterswelt
                  bezeichnet die Eignung des Produkts; ein Geburtsdatum des
                  Kindes wird nicht abgefragt.
                </td>
              </tr>
              <tr>
                <td>
                  Gebote, Bieterzuordnung, Zeitpunkte, Verkäufe, feste
                  Verkaufsbedingungen und Bestätigungen zur Abwicklung.
                </td>
                <td>
                  Auktionen durchführen, den Gewinner ermitteln und den Ablauf
                  für beide Beteiligten dokumentieren.
                </td>
              </tr>
              <tr>
                <td>
                  Inseratmeldungen mit damaligem Inseratstand,
                  Prüfentscheidungen, Verkaufsprobleme und Lösungen; Nachrichten
                  und Lesestatus.
                </td>
                <td>
                  Missbrauch prüfen, Probleme nachvollziehen und Beteiligte in
                  der App informieren.
                </td>
              </tr>
              <tr>
                <td>
                  Technische Verbindungsdaten wie IP-Adresse, Zeitpunkt,
                  angefragte Adresse, Browserinformationen und
                  Fehler-/Betriebsprotokolle.
                </td>
                <td>
                  Website ausliefern, Anmeldung und Datenzugriff betreiben,
                  Fehler finden und Missbrauch verhindern. Diese Daten fallen
                  auch bei den Infrastruktur-Anbietern an.
                </td>
              </tr>
              <tr>
                <td>E-Mails, die du dem Betreiber sendest.</td>
                <td>Deine Anfrage bearbeiten und beantworten.</td>
              </tr>
            </tbody>
          </table>
        </div>
        <p>
          Die Inhalte stammen aus deinen Eingaben und Uploads, den
          Handelsaktionen der Beteiligten und der Anmeldung über Google.
          Technische Protokolle entstehen beim Aufruf und Betrieb der Dienste.
        </p>
      </section>
      <section>
        <h2>3. Wer was sehen kann</h2>
        <p>
          Aktive Inserate, Produktfotos und der Anzeigename des Verkäufers sind
          öffentlich. Veröffentliche darin keine Kontaktadressen, Bankdaten,
          privaten Dokumente oder erkennbare Personen. Öffentlich zugängliche
          Inhalte können von Besuchern kopiert werden.
        </p>
        <p>
          Die Kontakt-E-Mail des Gegenübers wird nach dem Verkauf nur Käufer und
          Verkäufer in ihrem Konto angezeigt. Die gesamte Gebotshistorie,
          Kontodaten und Benachrichtigungen sind kein öffentlicher Feed.
        </p>
        <p>
          Inseratmeldungen und Prüfprotokolle sind für freigeschaltete
          Moderatoren zugänglich. Verkaufsprobleme sehen beide Beteiligte und,
          wenn ausdrücklich freigeschaltet, der Support. Der Betreiber besitzt
          als Administrator Zugang zur Datenbank und Bildablage, um Betrieb,
          Support und Datenschutzanfragen zu bearbeiten. Technische
          Dienstleister verarbeiten Daten für die unten genannten Dienste.
        </p>
      </section>
      <section>
        <h2>4. Dienstleister und Daten im Ausland</h2>
        <ul>
          <li>
            <strong>Vercel:</strong> Hosting und Auslieferung der WebApp,
            Verarbeitung von Anfragen und technischen Protokollen. Anbieter in
            den USA mit internationaler Infrastruktur.{" "}
            <a href="https://vercel.com/legal/privacy-notice">
              Datenschutzhinweise
            </a>{" "}
            und{" "}
            <a href="https://vercel.com/legal/dpa">
              Datenbearbeitungsvereinbarung
            </a>
            .
          </li>
          <li>
            <strong>Supabase:</strong> Konten und Anmeldung,
            PostgreSQL-Datenbank, Produktbilder und Auktionsabschluss. Die
            Projektregion ist Frankfurt, Deutschland (eu-central-1). Die
            gewählte Region bedeutet keine ausschliessliche Verarbeitung in
            Deutschland: Betrieb, Support und Unterauftragnehmer können Daten
            auch ausserhalb dieser Region bearbeiten.{" "}
            <a href="https://supabase.com/privacy">Datenschutzhinweise</a>,{" "}
            <a href="https://supabase.com/legal/customer-resources/data-processing-addendum">
              Datenbearbeitungsvereinbarung
            </a>{" "}
            und{" "}
            <a href="https://supabase.com/legal/customer-resources/subprocessor-list">
              Unterauftragnehmer
            </a>
            .
          </li>
          <li>
            <strong>Google:</strong> Anmeldung über dein bestehendes
            Google-Konto. Dabei werden die für die Anmeldung freigegebenen
            Kontodaten an Supabase übermittelt. Google verarbeitet die Anmeldung
            nach seinen eigenen Datenschutzregeln, auch mit internationaler
            Verarbeitung und in den USA.{" "}
            <a href="https://policies.google.com/privacy?hl=de">
              Google-Datenschutzerklärung
            </a>
            .
          </li>
          <li>
            <strong>E-Mail-Kontakt:</strong> Anfragen an die Betreiberadresse
            werden über Microsoft Outlook bearbeitet.{" "}
            <a href="https://privacy.microsoft.com/de-de/privacystatement">
              Microsoft-Datenschutzerklärung
            </a>
            .
          </li>
        </ul>
        <p>
          Damit findet Datenbearbeitung ausserhalb der Schweiz statt,
          insbesondere in Deutschland und den USA. Die Anbieter beschreiben ihre
          internationalen Datenübermittlungen und vertraglichen
          Schutzmechanismen in den verlinkten Unterlagen. Diese Anbieterhinweise
          ergänzen die Angaben zu kleinweiter und ersetzen sie nicht.
        </p>
      </section>
      <section>
        <h2>5. Cookies und Analyse</h2>
        <p>
          Für Anmeldung und Sitzung verwendet kleinweiter technisch notwendige
          Cookies, einschliesslich der Absicherung der Login-Rückleitung. Ohne
          diese Cookies ist die Anmeldung nicht nutzbar. Du kannst dich abmelden
          und Cookies in deinem Browser löschen; danach musst du dich erneut
          anmelden.
        </p>
        <p>
          In der App sind derzeit keine Werbetracker oder eigenen
          Analysewerkzeuge eingebaut. Es gibt keinen Newsletter und keine
          Weitergabe von Kontaktdaten zu Werbezwecken. Beim Wechsel zur
          Google-Anmeldung gelten zusätzlich die Cookie-Einstellungen und
          Datenschutzinformationen von Google.
        </p>
      </section>
      <section>
        <h2>6. Speicherung und Löschung</h2>
        <p>
          Konten, Inserate, Gebote, Verkäufe, Nachrichten und Prüfprotokolle
          bleiben im aktuellen Testbetrieb gespeichert; es gibt noch keine
          automatische Löschfrist oder Kontolöschung in der Oberfläche. Auch das
          Zurückziehen eines Inserats und das Entfernen eines Fotos aus der
          Galerie löschen die gespeicherten Datensätze bzw. Bilddateien nicht
          automatisch.
        </p>
        <p>
          Du kannst per E-Mail eine Prüfung der Löschung oder Berichtigung
          verlangen. Dabei berücksichtigen wir laufende Auktionen und Verkäufe,
          die Rechte anderer Beteiligter, offene Konflikte und notwendige
          Nachweise oder gesetzliche Aufbewahrungspflichten. Nicht mehr
          benötigte Daten sollen gelöscht oder anonymisiert werden; eine
          sofortige vollständige Löschung jeder Verkaufshistorie wird nicht
          zugesagt. Sicherungen und technische Protokolle der Anbieter
          unterliegen zusätzlich deren Aufbewahrungsregeln.
        </p>
      </section>
      <section>
        <h2>7. Schutz und automatische Abläufe</h2>
        <p>
          Die Verbindung verwendet HTTPS. Kontodaten, unveröffentlichte Uploads,
          Benachrichtigungen und Meldungen sind durch Anmeldung und
          Zugriffsrechte geschützt. Veröffentlichung, Gebote und Kaufabwicklung
          werden durch geprüfte Datenbankfunktionen verarbeitet.
        </p>
        <p>
          Der Auktionsgewinner wird anhand des gespeicherten höchsten gültigen
          Gebots automatisch ermittelt. Übergebote, Verkauf und Auktionsende
          lösen Nachrichten in der App aus. Es gibt keine automatische Text-
          oder Bildprüfung und kein werbliches Profiling. Gemeldete Inserate
          werden manuell geprüft.
        </p>
      </section>
      <section>
        <h2>8. Deine Rechte und Kontakt</h2>
        <p>
          Du kannst Auskunft über deine Personendaten, Berichtigung und eine
          Prüfung der Löschung verlangen sowie Einwände gegen die Bearbeitung
          vorbringen. Soweit die gesetzlichen Voraussetzungen erfüllt sind,
          kannst du auch die Herausgabe oder Übertragung deiner Daten verlangen.
        </p>
        <p>
          Schreibe an <a href={"mailto:" + operator.email}>{operator.email}</a>,
          möglichst von der E-Mail-Adresse deines kleinweiter-Kontos. Wir können
          einen angemessenen Identitätsnachweis verlangen, damit keine Daten an
          die falsche Person gelangen. Bitte sende unaufgefordert keine
          Ausweiskopie oder Passwörter. Du kannst dich auch an den{" "}
          <a href="https://www.edoeb.admin.ch/de">
            Eidgenössischen Datenschutz- und Öffentlichkeitsbeauftragten (EDÖB)
          </a>{" "}
          wenden.
        </p>
        <p>
          Wenn Funktionen oder Dienstleister geändert werden, wird diese
          Erklärung mit aktualisiertem Datum angepasst.
        </p>
      </section>
    </InfoShell>
  );
}
