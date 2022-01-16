source 'https://rubygems.org'

ruby '3.1.0'

gem 'dotenv-rails'
gem 'health_bit'
gem 'json', '~> 2.6.1'
gem 'jsonapi-serializer', '~> 2.2.0'
gem 'jbuilder', '~> 2.10'
gem 'nokogiri', '>= 1.10.9'
gem 'pg'
gem 'puma', '~> 5.5'
gem 'mailjet'
gem 'rails', '~> 6.1', '>= 6.1.4.1'
gem 'responders'
gem 'sass-rails'
gem 'sentry-ruby'
gem 'sentry-rails'
gem 'sidekiq'
gem 'sidekiq-scheduler', '~> 3.1'
gem 'turbolinks'
gem 'uglifier'
gem 'uri', '~> 0.11.0'
gem 'webpacker', '~> 5'
gem 'will_paginate'

# Until mail gem is updated
# https://stackoverflow.com/questions/70500220/rails-7-ruby-3-1-loaderror-cannot-load-such-file-net-smtp
gem 'net-smtp', require: false

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
