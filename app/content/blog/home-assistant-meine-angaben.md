---
title: "Home Assistant trägt Ihre Geräte in „Meine Angaben“ ein"
date: 2026-11-22
author: Christoph Fabianek
category: Digitales
summary: "Wer zu Hause Home Assistant nutzt, muss PV-Anlage, Batteriespeicher, Wärmepumpe und E-Auto nicht mehr von Hand eintragen: Die Integration „EEG GrünLicht“ schreibt sie in das Profil „Meine Angaben“. Eine Anleitung Schritt für Schritt — und was dabei übertragen wird."
draft: false
---

Sie nutzen zu Hause [Home Assistant](https://www.home-assistant.io/){: target="_blank" rel="noopener"}? Dann müssen Sie Ihre Geräte im Mitgliederportal nicht mehr von Hand eintragen. Home Assistant übernimmt das: Es trägt PV-Anlage, Batteriespeicher, Wärmepumpe und E-Auto in Ihr Profil **„Meine Angaben“** ein. Sie sehen die Geräte dann im [Mitgliederportal](https://abrechnung.eeg-gruenlicht.at/portal) und in der App GrünLicht.

Was Sie dort selbst eingetragen haben, bleibt. Meldet Home Assistant einen anderen Wert, sehen Sie einen Vorschlag. Den übernehmen Sie mit einem Klick.

Die Freigabe (Schritte 3 bis 7) haben wir am 22. November 2026 komplett durchgespielt: mit Home Assistant 2026.11 und der Integration „EEG GrünLicht“ 0.4.0. Home Assistant war dabei auf Englisch eingestellt. Wir nennen deshalb die englischen Bezeichnungen, so wie sie auf den Bildern stehen. Die Bilder zeigen einen Testhaushalt.
{: .blog-info}

## Was Sie brauchen

- **Home Assistant 2026.11** oder neuer
- ein Mitgliedskonto im [Mitgliederportal](https://abrechnung.eeg-gruenlicht.at/portal)
- ein kostenloses GitHub-Konto

Sie nutzen eine ältere Version von Home Assistant? Ab Version 2024.11 lässt sich die Integration über HACS installieren. Wie das geht, steht in der [Anleitung auf GitHub](https://github.com/GruenLicht/ha-eeg-gruenlicht){: target="_blank" rel="noopener"}.

## Schritt 1: Integration installieren

1. Öffnen Sie in Home Assistant **Settings** (Einstellungen) › **Marketplace**.
2. Klicken Sie oben rechts auf **„Add from link“**. Es öffnet sich das Fenster „Add from a GitHub link“.
3. Tragen Sie im Feld „GitHub link“ diese Adresse ein: `https://github.com/GruenLicht/ha-eeg-gruenlicht`
4. Klicken Sie auf **„Add“**.
5. Beim ersten Mal verbindet Home Assistant den Marketplace mit GitHub. Sie bekommen einen Code. Geben Sie ihn auf [github.com/login/device](https://github.com/login/device){: target="_blank" rel="noopener"} ein und bestätigen Sie.
6. Öffnen Sie im Marketplace **EEG GrünLicht** und klicken Sie auf **„Install“**.
7. Danach steht auf der Seite „Restart required“. Klicken Sie daneben auf **„Restart Home Assistant“**.
8. Es öffnet sich das Fenster „Restart Home Assistant“. Wählen Sie dort den Punkt **„Restart Home Assistant“** — nicht „Quick reload“.

[![Marketplace in Home Assistant mit dem Knopf „Add from link“ oben rechts und dem geöffneten Fenster „Add from a GitHub link“ mit dem Feld „GitHub link“ und den Knöpfen „Cancel“ und „Add“](/blog-assets/home-assistant-meine-angaben/12-add-from-link.jpg){: loading="lazy"}](/blog-assets/home-assistant-meine-angaben/12-add-from-link.jpg){: target="_blank" rel="noopener"}

Das Fenster „Add from a GitHub link“: Hier tragen Sie die Adresse ein.
{: .blog-caption}

[![Seite „Marketplace“ mit dem Hinweis „Restart required“ und dem Fenster „Restart Home Assistant“ mit den Punkten „Quick reload“ und „Restart Home Assistant“](/blog-assets/home-assistant-meine-angaben/02-neustart.jpg){: loading="lazy"}](/blog-assets/home-assistant-meine-angaben/02-neustart.jpg){: target="_blank" rel="noopener"}

Wählen Sie den unteren Punkt „Restart Home Assistant“.
{: .blog-caption}

**Kontrolle:** Nach dem Neustart steht im Marketplace bei EEG GrünLicht „Version v0.4.0 installed“ oder eine höhere Version. Die Freigabe für „Meine Angaben“ gibt es ab Version 0.4.0.

## Schritt 2: Mit dem Mitgliedskonto verbinden

1. Öffnen Sie **Settings** (Einstellungen) › **Devices & services** (Geräte & Dienste).
2. Klicken Sie unten rechts auf **„Add integration“** und wählen Sie **EEG GrünLicht**. Es öffnet sich das Fenster „Connect to EEG GrünLicht“.
3. Öffnen Sie in einem zweiten Fenster das [Mitgliederportal](https://abrechnung.eeg-gruenlicht.at/portal) und dort **„App verbinden“**. Unter dem QR-Code steht ein achtstelliger Kurzcode.
4. Tragen Sie den Kurzcode in Home Assistant im Feld „Short code“ ein und klicken Sie auf **„Submit“**.
5. Home Assistant zeigt einen sechsstelligen Code. Im Portal erscheint gleichzeitig eine Anfrage von „Home Assistant“.
6. Steht im Portal derselbe Code? Dann bestätigen Sie die Anfrage. Dafür haben Sie zwei Minuten Zeit.
7. Fertig: In Home Assistant erscheint **EEG GrünLicht** mit Ihren Daten.

[![Fenster „Connect to EEG GrünLicht“ in Home Assistant mit dem Hinweis auf „App verbinden“ im Mitgliederportal, dem Feld „Short code“ und dem Knopf „Submit“](/blog-assets/home-assistant-meine-angaben/13-verbinden.jpg){: loading="lazy"}](/blog-assets/home-assistant-meine-angaben/13-verbinden.jpg){: target="_blank" rel="noopener"}

Das Fenster „Connect to EEG GrünLicht“: Hier tragen Sie den Kurzcode aus dem Mitgliederportal ein.
{: .blog-caption}

## Schritt 3: Freigabe einschalten

1. Öffnen Sie **Settings** (Einstellungen) › **Devices & services** (Geräte & Dienste) › **EEG GrünLicht**.
2. Klicken Sie beim Eintrag auf das **Zahnrad-Symbol**. Es öffnet sich das Fenster „Permissions“.
3. Setzen Sie das Häkchen bei **„Enter devices in “Meine Angaben”“**. Auf Deutsch heißt die Freigabe „Geräte in „Meine Angaben“ eintragen“.
4. Lassen Sie die anderen Häkchen so, wie sie sind.
5. Klicken Sie auf **„Submit“**.

[![Fenster „Permissions“ mit drei Häkchen; das unterste heißt „Enter devices in “Meine Angaben”“. Rechts dahinter das Zahnrad-Symbol beim Eintrag der Integration](/blog-assets/home-assistant-meine-angaben/03-freigaben.jpg){: loading="lazy"}](/blog-assets/home-assistant-meine-angaben/03-freigaben.jpg){: target="_blank" rel="noopener"}

Das Fenster „Permissions“. Im Bild sind alle drei Freigaben eingeschaltet. Für „Meine Angaben“ brauchen Sie nur die unterste.
{: .blog-caption}

## Schritt 4: Geräte auswählen und ergänzen

Als Nächstes sehen Sie das Fenster „Devices“.

1. Unter „Detected devices“ stehen die Geräte, die Home Assistant erkannt hat. Lassen Sie sie angehakt.
2. Ergänzen Sie, was Home Assistant nicht weiß:
   - **„PV system power“:** Leistung der PV-Anlage in kWp
   - **„Battery capacity“:** Kapazität des Batteriespeichers in kWh
   - **„Heat pump electrical power“:** elektrische Leistung der Wärmepumpe in kW
   - **„Wallbox charging power“:** Ladeleistung der Wallbox in kW. Oder Sie setzen das Häkchen bei „I have an electric vehicle“.
3. Felder ohne Angabe können Sie leer lassen. Leere Felder und der Wert 0 werden nicht übertragen.
4. Klicken Sie auf **„Submit“**.
5. Zum Schluss steht im Fenster „Success“. Klicken Sie auf **„Finish“**.

Ist bei Ihnen auch das Haushaltsprofil eingeschaltet? Dann folgen vor „Success“ noch die Fenster „Electricity supply“ (Strombezug) und „Feed-in“ (Einspeisung), jeweils mit einem Fenster zum Tarif. Bestätigen Sie sie mit „Submit“.

[![Fenster „Devices“ mit vier erkannten Geräten (Wechselrichter, Batteriespeicher, Wärmepumpe, Zähler) und den Feldern „PV system power“, „Battery capacity“, „Heat pump electrical power“ und „Wallbox charging power“, darunter das Häkchen „I have an electric vehicle“](/blog-assets/home-assistant-meine-angaben/04-geraete.jpg){: loading="lazy"}](/blog-assets/home-assistant-meine-angaben/04-geraete.jpg){: target="_blank" rel="noopener"}

Das Fenster „Devices“ im Testhaushalt: oben die erkannten Geräte, darunter die Felder zum Ergänzen.
{: .blog-caption}

Im Testhaushalt blieb „Battery capacity“ leer. Home Assistant hat die Kapazität trotzdem gemeldet, weil es sie vom Speicher selbst kennt. Das Feld „Other devices or notes“ weiter unten geht nur in das Haushaltsprofil.

## Schritt 5: In Home Assistant kontrollieren

1. Öffnen Sie **Settings** (Einstellungen) › **Devices & services** (Geräte & Dienste) › **EEG GrünLicht**.
2. Klicken Sie auf die Zeile **EEG GrünLicht**, unter der „Mitgliedskonto“ steht. Es öffnet sich die Geräteseite.
3. Suchen Sie dort den Bereich „Diagnostic“.
4. Dort steht „Meine Angaben gemeldet“ mit einer Zeit von gerade eben. Im Bild ist es „1 minute ago“.

[![Geräteseite „EEG GrünLicht“ in Home Assistant mit Version 0.4.0; im Bereich „Diagnostic“ steht „Meine Angaben gemeldet“ mit „1 minute ago“](/blog-assets/home-assistant-meine-angaben/05-ha-geraeteseite.jpg){: loading="lazy"}](/blog-assets/home-assistant-meine-angaben/05-ha-geraeteseite.jpg){: target="_blank" rel="noopener"}

Die Geräteseite „EEG GrünLicht“: Unter „Diagnostic“ steht, wann „Meine Angaben“ zuletzt gemeldet wurden.
{: .blog-caption}

## Schritt 6: Im Mitgliederportal kontrollieren

1. Melden Sie sich im [Mitgliederportal](https://abrechnung.eeg-gruenlicht.at/portal) an.
2. Öffnen Sie **Profil** › **Meine Angaben**.
3. Weicht ein Wert aus Home Assistant von Ihrer eigenen Angabe ab? Dann steht darunter „Home Assistant meldet: …“. Ihre eigene Angabe bleibt vorerst stehen.
4. Soll der Wert aus Home Assistant gelten? Dann klicken Sie daneben auf **„Übernehmen“**.
5. Danach steht beim Wert „Gemeldet aus Home Assistant“ mit Datum.

Den Batteriespeicher finden Sie im Portal unter „Stromspeicher“.

[![Mitgliederportal, Profil › Meine Angaben: Unter Wärmepumpe, PV-Anlage und Stromspeicher steht jeweils ein Vorschlag „Home Assistant meldet: …“ mit dem Knopf „Übernehmen“](/blog-assets/home-assistant-meine-angaben/06-portal-meine-angaben.jpg){: loading="lazy"}](/blog-assets/home-assistant-meine-angaben/06-portal-meine-angaben.jpg){: target="_blank" rel="noopener"}

Drei Vorschläge im Testhaushalt: Home Assistant meldet andere Werte, als im Portal eingetragen sind.
{: .blog-caption}

[![Abschnitt Stromspeicher nach dem Übernehmen: Speicherkapazität 12,8 kWh, darunter „Gemeldet aus Home Assistant, 22.11.2026“](/blog-assets/home-assistant-meine-angaben/07-portal-uebernommen.jpg){: loading="lazy"}](/blog-assets/home-assistant-meine-angaben/07-portal-uebernommen.jpg){: target="_blank" rel="noopener"}

Nach dem Übernehmen: Beim Wert steht „Gemeldet aus Home Assistant“.
{: .blog-caption}

## Schritt 7: In der App GrünLicht

1. Öffnen Sie in der App den Reiter **„Mein Konto“**.
2. Tippen Sie auf **„Meine Angaben“**.
3. Sie sehen dieselbe Anzeige wie im Portal. „Übernehmen“ funktioniert auch hier.

Dafür brauchen Sie die App GrünLicht ab Version 1.2.0.

[![App GrünLicht, „Meine Angaben“: Elektrische Leistung der Wärmepumpe 2,1 kW, darunter der Vorschlag „Home Assistant meldet: 1,2 kW (22.11.2026)“ mit „Übernehmen“](/blog-assets/home-assistant-meine-angaben/09-app-vorschlag.jpg){: loading="lazy" .blog-narrow}](/blog-assets/home-assistant-meine-angaben/09-app-vorschlag.jpg){: target="_blank" rel="noopener"}

Ein Vorschlag in der App: Home Assistant meldet 1,2 kW.
{: .blog-caption}

[![App GrünLicht nach dem Übernehmen: Elektrische Leistung der Wärmepumpe 1,2 kW, „Gemeldet aus Home Assistant, 22.11.2026“, unten die Meldung „Übernommen“](/blog-assets/home-assistant-meine-angaben/10-app-uebernommen.jpg){: loading="lazy" .blog-narrow}](/blog-assets/home-assistant-meine-angaben/10-app-uebernommen.jpg){: target="_blank" rel="noopener"}

Nach dem Tippen auf „Übernehmen“: Die App bestätigt mit „Übernommen“.
{: .blog-caption}

## Gut zu wissen

- **Nur acht Angaben.** Über diese Freigabe werden übertragen: PV-Anlage ja/nein und Leistung, Batteriespeicher ja/nein und Kapazität, Wärmepumpe ja/nein und elektrische Leistung, E-Auto ja/nein und Ladeleistung der Wallbox. Keine Hersteller, keine Modelle, keine Messwerte, keine Gerätenamen.
- **Nie ein „nein“.** Home Assistant meldet nur, was es weiß. Ein „nein“ meldet es nie. Eine Ladeleistung bedeutet immer auch „E-Auto: ja“.
- **Einmal täglich.** Der Abgleich läuft einmal täglich und nach jeder Änderung in den Fenstern aus Schritt 3 und 4.
- **Ändern ja, löschen nein.** Solange die Freigabe eingeschaltet ist, können Sie einen Wert aus Home Assistant ändern, aber nicht löschen.
- **Freigabe abschalten.** Dazu entfernen Sie das Häkchen aus Schritt 3. Die Werte bleiben in „Meine Angaben“ stehen und werden nicht mehr geändert. Offene Vorschläge verschwinden. Die Werte lassen sich dann wieder löschen.
- **Was die Verwaltung sieht.** Die Verwaltung der EEG sieht, ob die Verbindung besteht, wann Home Assistant zuletzt Kontakt hatte, welche Version der Integration läuft und welche Freigaben eingeschaltet sind.
- **Freiwillig.** Die Freigabe ist freiwillig und standardmäßig aus.

[![Abschnitt Stromspeicher im Portal nach dem Abschalten der Freigabe: Speicherkapazität 12,8 kWh, „Gemeldet aus Home Assistant, 22.11.2026“, daneben die Knöpfe „Ändern“ und „Löschen“](/blog-assets/home-assistant-meine-angaben/11-portal-freigabe-aus.jpg){: loading="lazy"}](/blog-assets/home-assistant-meine-angaben/11-portal-freigabe-aus.jpg){: target="_blank" rel="noopener"}

Im Portal nach dem Abschalten der Freigabe: Der Wert bleibt stehen, und „Löschen“ ist wieder da.
{: .blog-caption}

[![App GrünLicht nach dem Abschalten der Freigabe: Speicherkapazität 12,8 kWh, „Gemeldet aus Home Assistant, 22.11.2026“, daneben „Ändern“ und das Papierkorb-Symbol](/blog-assets/home-assistant-meine-angaben/08-app-herkunft.jpg){: loading="lazy" .blog-narrow}](/blog-assets/home-assistant-meine-angaben/08-app-herkunft.jpg){: target="_blank" rel="noopener"}

In der App nach dem Abschalten der Freigabe: Der Papierkorb zum Löschen ist wieder da.
{: .blog-caption}

Das Haushaltsprofil ist eine eigene Freigabe mit eigenem Umfang. Was die Integration insgesamt überträgt, lesen Sie in unserer [Datenschutzinformation](/datenschutz).
