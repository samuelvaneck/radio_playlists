set :output, "#{path}/log/cron.log"

every 10.minutes do
  runner "Playlist.veronica"
end

every 1.day, at: '0:00 am' do
  runner "Playlist.reset_counters"
end

every 10.minutes do
  runner "Radio538playlist.538"
end

every 1.day, at: '0:00 am' do
  runner "Radio538playlist.reset_counters"
end

every 10.minutes do
  runner "Radio2playlist.radio2"
end

every 1.day, at: '0:00 am' do
  runner "Radio2playlist.reset_counters"
end

every 10.minutes do
  runner "Sublimefmplaylist.sublime"
end

every 1.day, at: '0:00 am' do
  runner "Sublimefmplaylist.reset_counters"
end

every 10.minutes do
  runner "Grootnieuwsplaylist.gnr"
end

every 1.day, at: '0:00 am' do
  runner "Grootnieuwsplaylist.reset_counters"
end
