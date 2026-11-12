# Formatierung der Energiepreise aus der EEG-Abrechnung (siehe EegPreise).
# Alle Preisangaben der Website laufen über diese Helfer — keine Preise fest im Text.
module PreiseHelper
  MONATE = %w[Jänner Februar März April Mai Juni Juli August September Oktober November Dezember].freeze

  # Ermäßigung des Netz-Arbeitspreises für Strom aus der Gemeinschaft im
  # Regionalbereich (Netzebenen 6 und 7). Das sind keine EEG-Preise, sondern
  # Werte der Systemnutzungsentgelte-Verordnung — bei einer neuen Verordnung
  # nur hier anpassen.
  NETZ_ERMAESSIGUNG_REGIONAL = { jahr: 2026, prozent: 28 }.freeze
  NETZ_ERMAESSIGUNG_REGIONAL_ENTWURF = { jahr: 2027, prozent: 22 }.freeze

  BEISPIEL_KWH = 20

  # Ein Stand je Request.
  def eeg_preise
    @eeg_preise ||= EegPreise.current
  end

  def preis_zahl(wert)
    number_with_precision(wert, precision: 2, strip_insignificant_zeros: true, separator: ",", delimiter: ".")
  end

  # 11 -> "11 ct/kWh", 9.3 -> "9,3 ct/kWh"
  def ct_kwh(wert)
    "#{preis_zahl(wert)} ct/kWh"
  end

  # Bereich mehrerer Preise: [10, 11] -> "10–11 ct/kWh"
  def ct_kwh_bereich(werte)
    werte = werte.uniq.sort
    return ct_kwh(werte.first) if werte.size == 1

    "#{preis_zahl(werte.first)}–#{preis_zahl(werte.last)} ct/kWh"
  end

  def euro(wert)
    "#{number_with_precision(wert, precision: 2, separator: ",", delimiter: ".")} €"
  end

  def preis_datum(datum)
    "#{datum.day}. #{MONATE[datum.month - 1]} #{datum.year}"
  end

  def preis_stand(zeit)
    return nil unless zeit

    "#{zeit.strftime("%d.%m.%Y")}, #{zeit.strftime("%H:%M")} Uhr"
  end

  # "1. Juli bis 31. Dezember 2026", "1. Jänner 2026 bis 30. Juni 2026"
  def preis_zeitraum(zeitraum)
    return "ab #{preis_datum(zeitraum.von)}" if zeitraum.bis.nil?

    von = zeitraum.von.year == zeitraum.bis.year ? "#{zeitraum.von.day}. #{MONATE[zeitraum.von.month - 1]}" : preis_datum(zeitraum.von)
    "#{von} bis #{preis_datum(zeitraum.bis)}"
  end

  # USt-Hinweis zum Bezugspreis einer Gemeinschaft.
  def ust_kurz(gemeinschaft)
    gemeinschaft.ust_frei? ? "USt-frei" : "inkl. #{preis_zahl(gemeinschaft.ust_prozent)} % USt"
  end

  # Aktueller Bezugspreis über alle Gemeinschaften, z.B. "11 ct/kWh USt-frei"
  # oder "10–11 ct/kWh (je nach Energiegemeinschaft)".
  def bezugspreis_kurz(stand = eeg_preise)
    preise = stand.bezugspreise
    return "noch nicht festgelegt" if preise.empty?

    text = ct_kwh_bereich(preise)
    text += " USt-frei" if stand.alle_ust_frei?
    text += " (je nach Energiegemeinschaft)" if preise.size > 1
    text
  end

  def einspeisepreis_kurz(stand = eeg_preise)
    preise = stand.einspeisepreise
    return "noch nicht festgelegt" if preise.empty?

    text = ct_kwh_bereich(preise)
    text += " (je nach Energiegemeinschaft)" if preise.size > 1
    text
  end

  # Kurzform für Bezug und Einspeisung zusammen, z.B. "11 ct/kWh USt-frei".
  def energiepreis_kurz(stand = eeg_preise)
    if stand.gleicher_preis_fuer_bezug_und_einspeisung? && stand.bezugspreise.size == 1
      bezugspreis_kurz(stand)
    else
      "Bezug #{bezugspreis_kurz(stand)}, Einspeisung #{einspeisepreis_kurz(stand)}"
    end
  end

  # Beschlossene künftige Preise je Gemeinschaft, z.B.
  # ["ab 1. Jänner 2027 in der EEG Grünes Licht Bad Vöslau: Bezug 12 ct/kWh, Einspeisung 12 ct/kWh"]
  def preisaenderungen(stand = eeg_preise)
    stand.gemeinschaften.flat_map do |g|
      g.kuenftig.map do |z|
        "ab #{preis_datum(z.von)} in der #{g.name}: Bezug #{ct_kwh(z.bezug)}, Einspeisung #{ct_kwh(z.einspeisung)}"
      end
    end
  end

  # "Der Preis ab 1. Jänner 2027 ist noch nicht festgelegt." (oder nil)
  def offene_preise_satz(stand = eeg_preise)
    offen = stand.gemeinschaften.select(&:offen_ab)
    return nil if offen.empty?

    if offen.size == stand.gemeinschaften.size && offen.map(&:offen_ab).uniq.size == 1
      "Der Preis ab #{preis_datum(offen.first.offen_ab)} ist noch nicht festgelegt."
    else
      offen.map { |g| "In der #{g.name} ist der Preis ab #{preis_datum(g.offen_ab)} noch nicht festgelegt." }.join(" ")
    end
  end

  def netz_ermaessigung_text
    jetzt = NETZ_ERMAESSIGUNG_REGIONAL
    entwurf = NETZ_ERMAESSIGUNG_REGIONAL_ENTWURF
    "#{jetzt[:jahr]} um #{jetzt[:prozent]}&nbsp;%, nach dem Tarifentwurf für #{entwurf[:jahr]} um #{entwurf[:prozent]}&nbsp;%".html_safe
  end

  def gebuehr_text(gebuehr)
    je = { "month" => "pro Monat", "year" => "pro Jahr", "invoice" => "pro Rechnung" }.fetch(gebuehr.je) { gebuehr.je.presence && "pro #{gebuehr.je}" }
    betrag = gebuehr.einheit == "EUR" ? euro(gebuehr.betrag) : "#{preis_zahl(gebuehr.betrag)} #{gebuehr.einheit}"
    ust = gebuehr.ust_prozent.nil? ? nil : (gebuehr.ust_prozent.zero? ? "USt-frei" : "zzgl. #{preis_zahl(gebuehr.ust_prozent)} % USt")
    [ "#{gebuehr.name}: #{betrag}", je, ust && "(#{ust})" ].compact.join(" ")
  end
end
