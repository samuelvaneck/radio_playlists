# Veronica checks and counter resets

desc "This task is called by the Heroku scheduler add-on"
task :playlist_check => :environment do
  puts "Checking current playing song Veronica....."
  Playlist.veronica
  puts "done!"
end

task :reset_counters => :environment do
  puts "Resetting day counters...."
  Playlist.reset_counters
  puts "done!"
end

# Radio 538 checks and counter resets

task :playlist_check_538 => :environment do
  puts "Checking current playing song Radio538....."
  Radio538playlist.radio538
  puts "done!"
end

task :reset_counters_538 => :environment do
  puts "Resetting day counters...."
  Radio538playlist.reset_counters
  puts "done!"
end

# Radio 2 checks and counter resets

task :playlist_check_radio2 => :environment do
  puts "Checking current playing song Radio 2....."
  Radio2playlist.radio2
  puts "done!"
end

task :reset_counters_radio2 => :environment do
  puts "Resetting day counters...."
  Radio2playlist.reset_counters
  puts "done!"
end

# Sublime FM checks and counters

task :playlist_check_sublimefm => :environment do
  puts "Checking current playing song Sublime FM....."
  Sublimefmplaylist.sublime
  puts "done!"
end

task :reset_counters_sublimefm => :environment do
  puts "Resetting day counters...."
  Sublimefmplaylist.reset_counters
  puts "done!"
end

# Groot Nieuws Radio checks and counter

task :playlist_check_gnr => :environment do
  puts "Checking current playing song Groot Nieuws Radio....."
  Grootnieuwsplaylist.gnr
  puts "done!"
end

task :reset_counters_gnr => :environment do
  puts "Resetting day counters...."
  Grootnieuwsplaylist.reset_counters
  puts "done!"
end
