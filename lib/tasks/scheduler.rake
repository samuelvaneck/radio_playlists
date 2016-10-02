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
  puts "Resetting week counters...."
  Playlist.reset_week_counters
  puts "done!"
end

task :reset_day_counter => :environment do
  puts "Resetting month counters...."
  Playlist.reset_month_counters
  puts "done!"
end

task :reset_day_counter => :environment do
  puts "Resetting year counters...."
  Playlist.reset_year_counters
  puts "done!"
end

task :playlist_checkt_538 => :environment do
  puts "Checking current playing song....."
  Radio538playlist.radio538
  puts "done!"
end

task :reset_day_countert_538 => :environment do
  puts "Resetting day counters...."
  Radio538playlist.reset_day_counters
  puts "done!"
end

task :reset_day_countert_538 => :environment do
  puts "Resetting week counters...."
  Radio538playlist.reset_week_counters
  puts "done!"
end

task :reset_day_countert_538 => :environment do
  puts "Resetting month counters...."
  Radio538playlist.reset_month_counters
  puts "done!"
end

task :reset_day_countert_538 => :environment do
  puts "Resetting year counters...."
  Radio538playlist.reset_year_counters
  puts "done!"
end
