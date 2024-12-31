source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.2", ">= 7.2.2.1"
# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# added by me for devise:
gem "devise", "4.9.4"
gem "bcrypt", "~> 3.1.20"
gem "responders", "~> 3.1"
gem "warden", "~> 1.2"
gem "orm_adapter", "~> 0.5"

# added by me for Active admin, an Admin interface for administrating users and more
gem "activeadmin", "~> 3.2.5"
gem "arbre", "~> 1.7.0"
gem "csv", "~> 3.3.2"
gem "formtastic", "~> 5.0.0"
gem "formtastic_i18n", "~> 0.7.0"
gem "inherited_resources", "~> 1.14.0"
gem "jquery-rails", "~> 4.6.0"
gem "kaminari", "~> 1.2.2"
gem "ransack", "~> 4.2.1"
gem "has_scope", "~> 0.8.2"
gem "kaminari-actionview", "~> 1.2.2"
gem "kaminari-activerecord", "~> 1.2.2"
gem "kaminari-core", "~> 1.2.2"
gem "sassc"

# added by me for uploading spreadsheets to the database
gem "roo"            # For reading Excel and CSV files
gem "activestorage"   # For uploading files

# added to generate dummy data for the users database table
gem "faker"






group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # added by me for better overview
  gem "annotate"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
