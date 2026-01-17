# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# Datenbank mit meist gebrauchten Dingen füllen

# Load option defaults
require_relative 'seeds/option_settings_defaults'

 Option.create([
   { name: "hat Posten geholt", count: 0, active: true },
   { name: "hat Mine gesetzt", count: 0, active: true },
   { name: "hat Gruppe fotografiert", count: 0, active: true },
   { name: "hat sondiert", count: 0, active: true },
   { name: "hat spioniert", count: 0, active: true },
   { name: "hat Foto bemerkt", count: 0, active: true },
   { name: "Spionageabwehr", count: 0, active: true },
   { name: "hat Kopfgeld gesetzt", count: 0, active: true },
   { name: "hat Mine entschärft", count: 0, active: true }
 ])

# Create OptionSettings for each option with defaults
Option.find_each do |option|
  next if option.option_setting.present?
  
  defaults = OPTION_DEFAULTS[option.name] || {}
  option.create_option_setting!(
    requires_photo: defaults[:requires_photo] || false,
    requires_target: defaults[:requires_target] || false,
    auto_verify: defaults[:auto_verify] || true,
    points: defaults[:points] || 0,
    cost: defaults[:cost] || 0,
    cooldown_seconds: defaults[:cooldown_seconds] || 0,
    rule_text: defaults[:rule_text],
    rule_text_default: defaults[:rule_text],
    available_to_players: defaults[:available_to_players] || true
  )
end

# Create GameSettings singleton
GameSetting.instance.tap do |settings|
  settings.save_as_defaults!
end

puts "✓ Options and settings created!"



# Added to make dummy users
if Rails.env.development?
  require 'faker'

  # Create 20 dummy users
  20.times do
    User.create!(
      name: Faker::Name.name,
      email: Faker::Internet.email,
      password: 'password',
      password_confirmation: 'password',
      phone_number: Faker::PhoneNumber.phone_number,
      group: nil # Ensures users are not assigned a group
    )
  end
  puts "20 dummy users created!"

end


# AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password') if Rails.env.development?
