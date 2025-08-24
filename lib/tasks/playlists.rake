namespace :air_plays do
  desc 'remove duplicate air plays'
  task deduplicate: :environment do
    AirPlay.find_each(&:deduplicate)
  end
end
