source 'https://rubygems.org'

ruby '3.4.1'

gem 'bootsnap', require: false
gem 'charlock_holmes', '~> 0.7.7'
gem 'csv', '~> 3.3', '>= 3.3.2'
gem 'dotenv-rails', '~> 3.1', '>= 2.8.1'
gem 'health_bit'
gem 'jaro_winkler'
gem 'json', '~> 2.9.1'
gem 'jsonapi-serializer', '~> 2.2.0'
gem 'mailjet'
gem 'newrelic_rpm'
gem 'nokogiri', '>= 1.10.9'
gem 'open3', '~> 0.2.1'
gem 'pg'
gem 'puma', '~> 6.4'
gem 'rack-cors', '~> 2.0', '>= 2.0.2'
gem 'rails', '~> 7.0', '>= 7.0.1'
gem 'redis'
gem 'sentry-ruby'
gem 'sentry-rails'
gem 'sidekiq'
gem 'sidekiq-scheduler', '~> 5.0'
gem 'sidekiq-unique-jobs', '~> 8.0'
gem 'turbolinks'
gem 'uglifier'
gem 'uri', '~> 1.0.2'
gem 'will_paginate'

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
  gem 'rubocop'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
  gem 'rspec-rails'
  gem 'selenium-webdriver', '~> 4.27'
  gem 'stackprof'
  gem 'webdrivers'
end

group :test do
  gem 'brakeman'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'shoulda-matchers'
  # Sinatra is used to mock requests
  gem 'sinatra'
  gem 'simplecov'
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'bullet'
  gem 'annotate'
  gem 'foreman'
  gem 'letter_opener'
  gem 'spring'
  gem 'web-console'
end
