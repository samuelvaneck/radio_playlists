set :output, "#{path}/log/cron.log"

every 10.minutes do
  runner "Playlist.veronica"
end
