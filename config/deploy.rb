# frozen_string_literal: true

set :application, 'radio_playlists'
set :repo_url, 'git@github.com:samuelvaneck/radio_playlists.git'

set :deploy_to, '/home/deploy/radio_playlists'

set :passenger_restart_with_touch, false

append :linked_files, 'config/database.yml', 'config/secrets.yml'
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', "public/uploads"

namespace :deploy do
  after :finishing, 'apache:reload'
  after :rollback, 'apache:reload'
end
