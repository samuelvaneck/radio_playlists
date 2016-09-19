desc "This task is called by the Heroku scheduler add-on"
task :playlist_check => :environment do
  puts "Checking current playing song....."
  Playlist.veronica
  puts "done."
end
