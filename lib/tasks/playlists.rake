namespace :playlists do
  desc 'remove duplicate playlists'
  task deduplicate: :environment do
    Playlist.find_each(&:deduplicate)
  end
end
