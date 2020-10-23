# frozen_string_literal: true

set :application, 'radio_playlists'
set :repo_url, 'git@github.com:samuelvaneck/radio_playlists.git'

set :deploy_to, '/home/deploy/radio_playlists'

set :passenger_restart_with_touch, false

# sidekiq config
set :pty, true
set :ssh_options, { forward_agent: true }
set :sidekiq_role, :app
set :sidekiq_config, -> { File.join(shared_path, 'config', 'sidekiq.yml') }
set :sidekiq_env, 'production'
set :nginx_sudo_tasks, ['nginx:restart']

append :linked_files, 'config/database.yml', 'config/secrets.yml'
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', "public/uploads"

# namespace :deploy do
#   after :finishing, 'nginx:reload'
#   after :rollback, 'nginx:reload'
# end

task :add_default_hooks do
  after 'deploy:updated', 'sidekiq:stop'
  after 'deploy:reverted', 'sidekiq:stop'
  after 'deploy:published', 'sidekiq:start'
end

# namespace :apache do
#   task :reload do
#     on roles(:app) do
#       execute :sudo, :systemctl, :restart, :apache2
#     end
#   end
# end

namespace :sidekiq do
  task :start do
    on roles(:app) do
      execute :sudo, :systemctl, :start, :sidekiq
    end
  end
  task :stop do
    on roles(:app) do
      execute :sudo, :systemctl, :stop, :sidekiq
    end
  end
  task :restart do
    on roles(:app) do
      execute :sudo, :systemctl, :restart, :sidekiq
    end
  end
end
