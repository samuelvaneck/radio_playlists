namespace :playlists do
  desc 'remove duplicate playlists'
  task deduplicate: :environment do
    Generalplaylist.find_each(&:deduplicate)
  end
end
