env :PATH, ENV['PATH']

set :output, "#{path}/log/cron.log"

every '1-59/3 * * * *' do
  runner "Generalplaylist.radio_veronica_check"
end

every '2-59/3 * * * *' do
  runner "Generalplaylist.radio_538_check"
end

every '1-59/3 * * * *' do
  runner "Generalplaylist.radio_2_check"
end

every '2-59/3 * * * *' do
  runner "Generalplaylist.sublime_fm_check"
end

every '1-59/3 * * * *' do
  runner "Generalplaylist.grootnieuws_radio_check"
end

every '2-59/3 * * * *' do
  runner "Generalplaylist.sky_radio_check"
end

every '1-59/3 * * * *' do
  runner "Generalplaylist.radio_3fm_check"
end

every '2-59/3 * * * *' do
  runner "Generalplaylist.q_music_check"
end

every 1.day, at: '0:00 am' do
  runner "Generalplaylist.reset_counters"
end

every 1.day, at: "0.00 am" do
  command "rm -rf #{path}/log/cron.log"
end
