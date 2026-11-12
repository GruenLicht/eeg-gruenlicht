# Grundeinrichtung des Beta-Forums (forum-beta.eeg-gruenlicht.at).
# Idempotent: kann beliebig oft laufen, legt Fehlendes an und setzt Rechte neu.
#
# Ausfuehren im Discourse-Pod:
#   cd /var/www/discourse && sudo -E -u discourse HOME=/home/discourse bin/rails runner /tmp/forum-beta-setup.rb

SiteSetting.default_locale = "de"
SiteSetting.title = "EEG GrünLicht Forum (Beta)"
SiteSetting.login_required = false

mitglieder = Group.find_or_create_by!(name: "mitglieder") do |g|
  g.full_name = "Mitglieder der EEG GrünLicht"
end
puts "Gruppe: #{mitglieder.name} (id #{mitglieder.id})"

# [Name, Slug, Farbe, Rechte, Beschreibung]
KATEGORIEN = [
  ["Willkommen & Onboarding", "willkommen-onboarding", "15803D", { everyone: :full },
   "Fragen rund um den Beitritt: Voraussetzungen, Smart-Meter-Webportal, Freigabe bei den Wiener Netzen. Hier können auch Interessierte schreiben."],
  ["Abrechnung & Preise", "abrechnung-preise", "0E7490", { "mitglieder" => :full },
   "Monatliche Abrechnungsinformation, Preise, Auszahlung."],
  ["Home Assistant & Energie optimieren", "home-assistant", "7C3AED", { "mitglieder" => :full },
   "GrünLicht-Plugin, Lastspitzen, Verbrauch in sonnige Stunden verschieben."],
  ["PV, Speicher & Technik", "pv-speicher-technik", "B45309", { "mitglieder" => :full },
   "Anlagen, Wechselrichter, Speicher, Erfahrungen mit Installateuren."],
  ["Neuigkeiten & Treffen", "neuigkeiten-treffen", "64748B", { "mitglieder" => :create_post, staff: :full },
   "Neuigkeiten aus dem Verein und Community-Treffen. Themen eröffnet der Vorstand, alle Mitglieder können antworten."],
]

KATEGORIEN.each_with_index do |(name, slug, color, rechte, beschreibung), i|
  kategorie = Category.find_by(slug: slug) ||
              Category.new(name: name, slug: slug, user: Discourse.system_user)
  kategorie.name = name
  kategorie.color = color
  kategorie.text_color = "FFFFFF"
  kategorie.position = i
  kategorie.description = beschreibung
  kategorie.set_permissions(rechte)
  kategorie.save!
  gruppen = kategorie.category_groups.map { |g| [g.group.name, g.permission_type] }
  puts [kategorie.id, kategorie.slug, kategorie.read_restricted, gruppen].inspect
end

# --- Oberfläche für Mitglieder vereinfachen ---------------------------------
SiteSetting.chat_enabled = false          # kein Chat, keine Kanäle/Direktnachrichten-Leiste
SiteSetting.tagging_enabled = false       # keine Schlagwörter
SiteSetting.enable_user_status = false    # keine Status-Emojis am Profil
# Direktnachrichten: nur das Team darf welche schreiben (z. B. Moderationshinweise),
# Mitglieder untereinander nicht.
SiteSetting.personal_message_enabled_groups = Group::AUTO_GROUPS[:staff].to_s
SiteSetting.top_menu = "categories|latest|new"
SiteSetting.desktop_category_page_style = "categories_and_latest_topics"

eigene = Category.where(slug: KATEGORIEN.map { |k| k[1] }).order(:position)
SiteSetting.default_navigation_menu_categories = eigene.pluck(:id).join("|")

# Standard-Kategorien von Discourse nur noch für das Team sichtbar
onboarding = Category.find_by!(slug: "willkommen-onboarding")
%w[general site-feedback].each do |slug|
  kategorie = Category.find_by(slug: slug)
  next unless kategorie
  kategorie.set_permissions(staff: :full)
  kategorie.save!
  puts "ausgeblendet: #{slug}"
end

# Begrüßungsthema in die Onboarding-Kategorie verschieben
if (willkommen = Topic.find_by(id: SiteSetting.welcome_topic_id)) && willkommen.category_id != onboarding.id
  willkommen.change_category_to_id(onboarding.id)
  puts "Begrüßungsthema verschoben: #{willkommen.title}"
end

admins = User.where(admin: true).where("id > 0").map { |u| [u.username, u.email] }
puts "Admins: #{admins.inspect}"
