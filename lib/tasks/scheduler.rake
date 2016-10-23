# Veronica checks and counter resets

desc "This task is called by the Heroku scheduler add-on"
task :playlist_check => :environment do
  puts "Checking current playing song Veronica....."
  Playlist.veronica
  puts "done!"
end

task :reset_day_counter => :environment do
  puts "Resetting day counters...."
  Playlist.reset_day_counters
  puts "done!"
end

task :reset_week_counter => :environment do
  puts "Resetting week counters...."
  Playlist.reset_week_counters
  puts "done!"
end

task :reset_month_counter => :environment do
  puts "Resetting month counters...."
  Playlist.reset_month_counters
  puts "done!"
end

task :reset_year_counter => :environment do
  puts "Resetting year counters...."
  Playlist.reset_year_counters
  puts "done!"
end

# Radio 538 checks and counter resets

task :playlist_check_538 => :environment do
  puts "Checking current playing song Radio538....."
  Radio538playlist.radio538
  puts "done!"
end

task :reset_day_counter_538 => :environment do
  puts "Resetting day counters...."
  Radio538playlist.reset_day_counters
  puts "done!"
end

task :reset_week_counter_538 => :environment do
  puts "Resetting week counters...."
  Radio538playlist.reset_week_counters
  puts "done!"
end

task :reset_month_counter_538 => :environment do
  puts "Resetting month counters...."
  Radio538playlist.reset_month_counters
  puts "done!"
end

task :reset_year_counter_538 => :environment do
  puts "Resetting year counters...."
  Radio538playlist.reset_year_counters
  puts "done!"
end

# Radio 2 checks and counter resets

task :playlist_check_radio2 => :environment do
  puts "Checking current playing song Radio 2....."
  Radio2playlist.radio2
  puts "done!"
end

task :reset_day_counter_radio2 => :environment do
  puts "Resetting day counters...."
  Radio2playlist.reset_day_counters
  puts "done!"
end

task :reset_week_counter_radio2 => :environment do
  puts "Resetting week counters...."
  Radio2playlist.reset_week_counters
  puts "done!"
end

task :reset_month_counter_radio2 => :environment do
  puts "Resetting month counters...."
  Radio2playlist.reset_month_counters
  puts "done!"
end

task :reset_year_counter_radio2 => :environment do
  puts "Resetting year counters...."
  Radio2playlist.reset_year_counters
  puts "done!"
end

# Sublime FM checks and counters

task :playlist_check_sublimefm => :environment do
  puts "Checking current playing song Radio 2....."
  Sublimefmplaylist.sublime
  puts "done!"
end

task :reset_day_counter_sublimefm => :environment do
  puts "Resetting day counters...."
  Sublimefmplaylist.reset_day_counters
  puts "done!"
end

task :reset_week_counter_sublimefm => :environment do
  puts "Resetting week counters...."
  Sublimefmplaylist.reset_week_counters
  puts "done!"
end

task :reset_month_counter_sublimefm => :environment do
  puts "Resetting month counters...."
  Sublimefmplaylist.reset_month_counters
  puts "done!"
end

task :reset_year_counter_sublimefm => :environment do
  puts "Resetting year counters...."
  Sublimefmplaylist.reset_year_counters
  puts "done!"
end

# Groot Nieuws Radio checks and counter

task :playlist_check_gnr => :environment do
  puts "Checking current playing song Radio 2....."
  Grootnieuwsplaylist.gnr
  puts "done!"
end

task :reset_day_counter_gnr => :environment do
  puts "Resetting day counters...."
  Grootnieuwsplaylist.reset_day_counters
  puts "done!"
end

task :reset_week_counter_gnr => :environment do
  puts "Resetting week counters...."
  Grootnieuwsplaylist.reset_week_counters
  puts "done!"
end

task :reset_month_counter_gnr => :environment do
  puts "Resetting month counters...."
  Grootnieuwsplaylist.reset_month_counters
  puts "done!"
end

task :reset_year_counter_gnr => :environment do
  puts "Resetting year counters...."
  Grootnieuwsplaylist.reset_year_counters
  puts "done!"
end
