set :output, "#{path}/log/cron.log"

every 3.minutes do
  runner "Generalplaylist.radio_veronica_check"
end

every 3.minutes do
  runner "Generalplaylist.radio_538_check"
end

every 3.minutes do
  runner "Generalplaylist.radio_2_check"
end

every 3.minutes do
  runner "Generalplaylist.sublime_fm_check"
end

every 3.minutes do
  runner "Generalplaylist.grootnieuws_radio_check"
end

every 1.hour do
  runner "Generalplaylist.sky_radio_check"
end

every 3.minutes do
  runner "Generalplaylist.radio_3fm_check"
end

every 3.minutes do
  runner "Generalplaylist.q_music_check"
end

every 1.day, at: '0:00 am' do
  runner "Generalplaylist.reset_counters"
end

every 1.day, at: "0.00 am" do
  command "rm -rf #{path}/log/cron.log"
end
