# frozen_string_literal: true

namespace :lastfm do
  desc 'Enrich songs with Last.fm data'
  task enrich_songs: :environment do
    enricher = Lastfm::SongEnricher.new
    
    songs_to_enrich = Song.where(lastfm_url: nil).limit(100)
    
    songs_to_enrich.find_each do |song|
      next if song.artists.blank?
      
      puts "Enriching song: #{song.search_text}"
      enricher.enrich_song(song)
      
      # Rate limiting - Last.fm allows 5 requests per second
      sleep 0.2
    rescue StandardError => e
      puts "Error enriching song #{song.id}: #{e.message}"
      next
    end
    
    puts "Enrichment complete!"
  end

  desc 'Enrich artists with Last.fm data'
  task enrich_artists: :environment do
    enricher = Lastfm::SongEnricher.new
    
    artists_to_enrich = Artist.where(lastfm_url: nil).limit(100)
    
    artists_to_enrich.find_each do |artist|
      puts "Enriching artist: #{artist.name}"
      enricher.enrich_artist(artist)
      
      # Rate limiting - Last.fm allows 5 requests per second
      sleep 0.2
    rescue StandardError => e
      puts "Error enriching artist #{artist.id}: #{e.message}"
      next
    end
    
    puts "Enrichment complete!"
  end

  desc 'Search for a track on Last.fm'
  task :search_track, [:query] => :environment do |_task, args|
    query = args[:query]
    
    if query.blank?
      puts "Usage: rails lastfm:search_track['Artist - Track Name']"
      exit
    end
    
    enricher = Lastfm::SongEnricher.new
    results = enricher.search_tracks(query)
    
    if results.empty?
      puts "No results found for: #{query}"
    else
      puts "\nSearch results for: #{query}\n"
      puts "-" * 50
      
      results.each_with_index do |track, index|
        puts "\n#{index + 1}. #{track[:artist]} - #{track[:name]}"
        puts "   URL: #{track[:url]}"
        puts "   Listeners: #{track[:listeners]}" if track[:listeners]
      end
    end
  end

  desc 'Search for an artist on Last.fm'
  task :search_artist, [:query] => :environment do |_task, args|
    query = args[:query]
    
    if query.blank?
      puts "Usage: rails lastfm:search_artist['Artist Name']"
      exit
    end
    
    enricher = Lastfm::SongEnricher.new
    results = enricher.search_artists(query)
    
    if results.empty?
      puts "No results found for: #{query}"
    else
      puts "\nSearch results for: #{query}\n"
      puts "-" * 50
      
      results.each_with_index do |artist, index|
        puts "\n#{index + 1}. #{artist[:name]}"
        puts "   URL: #{artist[:url]}"
        puts "   Listeners: #{artist[:listeners]}" if artist[:listeners]
      end
    end
  end

  desc 'Test Last.fm API connection'
  task test_connection: :environment do
    if ENV['LASTFM_API_KEY'].present?
      puts "✓ Last.fm API key is configured"
      
      # Try a simple API call
      track_finder = Lastfm::TrackFinder.new
      result = track_finder.search('The Beatles', 'Hey Jude', limit: 1)
      
      if result
        puts "✓ API connection successful"
        puts "  Test search returned: #{result.first[:name]} by #{result.first[:artist]}"
      else
        puts "✗ API connection failed - check your API key"
      end
    else
      puts "✗ Last.fm API key not configured"
      puts "  Please set LASTFM_API_KEY environment variable"
    end
  end
end