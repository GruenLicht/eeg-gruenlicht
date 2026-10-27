---
title: "Der EEG-Assistent: Fragen zu Ihren Energiedaten — beantwortet von unserer eigenen KI in Bad Vöslau"
date: 2026-10-27
author: Christoph Fabianek
category: Digitales
summary: "Im Abrechnungsportal testen wir einen neuen Helfer: den EEG-Assistenten. Er beantwortet Fragen zu Ihren eigenen Energiedaten in ganzen Sätzen. Das Besondere: Die KI dahinter läuft nicht in einem fernen Rechenzentrum, sondern auf einem sparsamen Rechner bei uns in Bad Vöslau — mit Strom aus unserer Energiegemeinschaft."
draft: false
unlisted: true
---

Wie viel Strom habe ich im letzten Monat erzeugt? Wie viel davon ist in der Gemeinschaft geblieben? Wann war meine höchste Lastspitze? Die Antworten stecken in Ihren Messdaten — bisher mussten Sie sie aber selbst aus Tabellen und Grafiken herauslesen.

Dafür testen wir derzeit den **EEG-Assistenten**: einen Chat im [Abrechnungsportal](https://abrechnung.eeg-gruenlicht.at/portal), dem Sie Fragen in Alltagssprache stellen. Er sucht die passenden Werte aus Ihren Daten heraus, rechnet nach und antwortet in ganzen Sätzen.

## Was der EEG-Assistent kann

Sie finden ihn im Portal im Reiter **„EEG-Assistent"**. Fragen Sie zum Beispiel:

- „Wie viel habe ich im letzten Monat erzeugt und verbraucht?"
- „Welche Zählpunkte gehören mir?"
- „Wann war im September meine höchste [Lastspitze](/blog/lastspitze-2027-portal-und-app)?"
- „Erkläre mir die Informationen in der [monatlichen Abrechnung](/blog/abrechnung-erklaert)!"

Wo es hilft, zeigt der Assistent auch den Rechenweg. Ein Beispiel aus unserem Test: Auf die Frage, ob in einer Viertelstunde im August mehr als 10 kWh bezogen wurden, rechnete er vor, dass dafür eine Leistung von 40 kW nötig wäre (10 kWh in einer Viertelstunde), die höchste gemessene Spitze aber bei 4,07 kW lag — also eindeutig nein.

## Unsere eigene, sparsame KI — mitten in Bad Vöslau

Die meisten KI-Chats laufen in riesigen Rechenzentren großer Konzerne, auf Tausenden Grafikkarten mit entsprechendem Strom- und Kühlbedarf. Wir gehen einen anderen Weg.

[![Technikschrank in Bad Vöslau: oben Datenspeicher und Router, in der Mitte das Notebook, auf dem der EEG-Assistent läuft, unten die unterbrechungsfreie Stromversorgung](/blog-assets/eeg-assistent/technikschrank.jpg){: loading="lazy" .blog-medium}](/blog-assets/eeg-assistent/technikschrank.jpg){: target="_blank" rel="noopener"}

Der EEG-Assistent läuft auf einem einzigen Rechner in unserem Technikschrank in Bad Vöslau: einem älteren Apple-Notebook mit M1-Chip (im Bild auf dem mittleren Boden), das damit ein zweites Leben bekommt. Darauf arbeitet ein frei verfügbares Sprachmodell — vollständig auf diesem Gerät, ohne Umweg über einen Cloud-Dienst.

- **Sparsam:** Der M1-Chip ist auf geringen Stromverbrauch ausgelegt. Im Leerlauf braucht der Rechner nur wenige Watt, und auch beim Antworten liegt er weit unter einem Rechenzentrums-Server mit Grafikkarten, der mehrere Hundert Watt zieht.
- **Mit Strom aus der Gemeinschaft:** Der Schrank bezieht seinen Strom über die EEG Grünes Licht Bad Vöslau/Sooß — wenn die Sonne scheint, also direkt von den Dächern unserer Mitglieder.
- **Regional:** Die Rechenarbeit für Ihre Fragen passiert hier in der Region, nicht auf einem anderen Kontinent.

Der Preis dafür: Ein kleiner Rechner ist langsamer als ein Rechenzentrum. Einfache Fragen beantwortet der Assistent in einigen Sekunden, aufwendige können auch eine Minute oder länger dauern. Das Portal zeigt währenddessen an, wie lange er schon „denkt", und unter jeder Antwort die Antwortzeit.

## Ihre Daten bleiben bei uns

- **Kein großer KI-Anbieter:** Ihre Fragen und Ihre Energiedaten gehen an keinen KI-Dienst eines Konzerns. Betrieben wird der Assistent von unserem Verein selbst.
- **Nur Ihre eigenen Daten:** Für jede Frage stellt das Portal einen Zugangsschlüssel aus, der nur wenige Minuten gilt und nur zu Ihrem Konto passt. Die Daten anderer Mitglieder kann der Assistent nicht abrufen.
- **Nur lesen:** Der Assistent kann nichts ändern — keine Stammdaten, keine Einstellungen, keine Abrechnung.

## Noch in der Testphase

Derzeit probiert eine kleine Gruppe von Mitgliedern den Assistenten aus. Wenn er sich bewährt, schalten wir ihn schrittweise für alle frei.

**Die Antworten erzeugt eine KI — sie können Fehler enthalten.** Maßgeblich sind immer Ihre Abrechnungen und die Werte im Portal. Wenn Ihnen eine Antwort seltsam vorkommt, prüfen Sie sie dort nach.
{: .blog-info}

Gerade jetzt sind Rückmeldungen besonders wertvoll. Neben dem Eingabefeld gibt es dafür die Schaltfläche **„Feedback"**: Sie vergeben ein bis fünf Sterne, können eine Nachricht schreiben und auf Wunsch den Verlauf der Unterhaltung mitschicken — wenn Sie möchten, auch anonym.

Haben Sie Fragen oder Ideen, was der Assistent noch können sollte? [Schreiben Sie uns](/#kontakt) — wir freuen uns darauf.
