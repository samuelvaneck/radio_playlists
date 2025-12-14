source 'https://rubygems.org'

ruby '3.4.7'

gem 'bootsnap', require: false
gem 'charlock_holmes', '~> 0.7.7'
gem 'csv', '~> 3.3', '>= 3.3.2'
gem 'devise'
gem 'devise-jwt'
gem 'dotenv-rails', '~> 3.1', '>= 2.8.1'
gem 'faraday', '~> 2.13'
gem 'health_bit'
gem 'jaro_winkler'
gem 'json', '~> 2.13.2'
gem 'jsonapi-serializer', '~> 2.2.0'
gem 'mailjet'
gem 'newrelic_rpm'
gem 'nokogiri', '>= 1.10.9'
gem 'open3', '~> 0.2.1'
gem 'pg'
gem 'puma', '~> 7.0'
gem 'rack-cors', '~> 3.0', '>= 2.0.2'
gem 'rails', '~> 8.0', '>= 8.0.1'
gem 'connection_pool', '~> 2.5' # Pinned until Rails 8.1 is compatible with connection_pool 3.0
gem 'redis'
gem 'sentry-ruby'
gem 'sentry-rails'
gem 'sidekiq'
gem 'sidekiq-scheduler', '~> 6.0'
gem 'sidekiq-unique-jobs', '~> 8.0'
gem 'turbolinks'
gem 'uglifier'
gem 'uri', '~> 1.0.2'
gem 'will_paginate'
gem 'seed-fu', '~> 2.3'

# Until mail gem is updated
# https://github.com/mikel/mail/pull/1439
gem 'net-smtp'
gem 'net-pop'
gem 'net-imap'

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
  gem 'rubocop-factory_bot'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
  gem 'rubocop-rspec_rails'
  gem 'rspec-rails'
  gem 'stackprof'
end

group :test do
  gem 'brakeman'
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
  gem 'annotaterb'
  gem 'bullet'
  gem 'foreman'
  gem 'letter_opener'
  gem 'spring'
  gem 'web-console'
end
