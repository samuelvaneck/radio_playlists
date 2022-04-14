source 'https://rubygems.org'

ruby '3.1.2'

gem 'dotenv-rails'
gem 'health_bit'
gem 'json', '~> 2.6.1'
gem 'jsonapi-serializer', '~> 2.2.0'
gem 'jbuilder', '~> 2.10'
gem 'nokogiri', '>= 1.10.9'
gem 'pg'
gem 'puma', '~> 5.6'
gem 'mailjet'
gem 'rails', '~> 7.0', '>= 7.0.1'
gem 'responders'
gem 'sentry-ruby'
gem 'sentry-rails'
gem 'sidekiq'
gem 'sidekiq-scheduler', '~> 3.1'
gem 'sprockets-rails', require: 'sprockets/railtie'
gem 'turbolinks'
gem 'uglifier'
gem 'uri', '~> 0.11.0'
gem 'will_paginate'

gem 'jsbundling-rails', '~> 1.0'
gem 'cssbundling-rails', '~> 1.0'

# Until mail gem is updated
# https://github.com/mikel/mail/pull/1439
gem 'net-smtp', require: false
gem 'net-pop', require: false
gem 'net-imap', require: false


group :development, :test do
  gem 'concurrent-ruby'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'guard-rspec'
  gem 'launchy'
  gem 'listen'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

group :test do
  gem 'brakeman'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'rubocop'
  gem 'shoulda-matchers'
  # Sinatra is used to mock requests
  gem 'sinatra'
  gem 'simplecov'
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'letter_opener'
  gem 'spring'
  gem 'web-console'
end
