set :application, "radio_playlists"
set :repo_url, "git@github.com:sam365/radio_playlists.git"

set :deploy_to, '/home/deploy/radio_playlists'

append :linked_files, "config/database.yml", "config/secrets.yml"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "vendor/bundle", "public/system", "public/uploads"
