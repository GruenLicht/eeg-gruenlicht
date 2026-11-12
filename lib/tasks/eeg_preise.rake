namespace :eeg_preise do
  desc "Schnappschuss der Preise aus der EEG-Abrechnung nach config/eeg_preise.json schreiben (Rückfall, wenn die Schnittstelle nicht antwortet)"
  task snapshot: :environment do
    url = ENV["EEG_PREISE_URL"].presence || EegPreise::DEFAULT_URL
    ENV["EEG_PREISE_URL"] = url
    json = EegPreise.fetch_json

    if json
      File.write(EegPreise::SNAPSHOT_PATH, JSON.pretty_generate(json) + "\n")
      puts "eeg_preise: Schnappschuss von #{url} geschrieben (Stand #{json["generated_at"]})"
    else
      # Kein Abbruch: Der Build soll nicht an der Schnittstelle hängen, es bleibt der bisherige Schnappschuss.
      warn "eeg_preise: Schnittstelle nicht erreichbar, bisheriger Schnappschuss bleibt (#{EegPreise::SNAPSHOT_PATH})"
    end
  end
end
