desc "This task is called by the Heroku scheduler add-on"
task :playlist_check => :environment do
  puts "Checking current playing song....."
  Playlist.veronica
  puts "done!"
end

task :reset_day_counter => :environment do
  puts "Resetting day counters...."
  Playlist.reset_day_counters
  puts "done!"
end

task :reset_day_counter => :environment do
  puts "Resetting day counters...."
  Playlist.reset_week_counters
  puts "done!"
end

task :reset_day_counter => :environment do
  puts "Resetting day counters...."
  Playlist.reset_month_counters
  puts "done!"
end

task :reset_day_counter => :environment do
  puts "Resetting day counters...."
  Playlist.reset_year_counters
  puts "done!"
end
