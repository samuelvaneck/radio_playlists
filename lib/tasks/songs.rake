# frozen_string_literal: true

namespace :songs do
  desc 'Find songs with suspicious airplay patterns (many stations in short time)'
  task find_suspicious: :environment do
    puts 'Finding songs with suspicious airplay patterns...'
    puts '=' * 80

    # Find songs that have airplays from many different stations within a short time window
    suspicious_songs = Song.joins(:air_plays)
                         .where(air_plays: { broadcasted_at: 24.hours.ago.. })
                         .group('songs.id')
                         .having('COUNT(DISTINCT air_plays.radio_station_id) >= 5')
                         .having('MAX(air_plays.broadcasted_at) - MIN(air_plays.broadcasted_at) < interval \'30 minutes\'')
                         .select('songs.*, COUNT(DISTINCT air_plays.radio_station_id) as station_count')

    if suspicious_songs.empty?
      puts 'No suspicious songs found.'
    else
      suspicious_songs.each do |song|
        song_with_artists = Song.includes(:artists, :air_plays).find(song.id)
        puts "\nSong ID: #{song.id}"
        puts "Title: #{song_with_artists.title}"
        puts "Artists: #{song_with_artists.artists.map(&:name).join(', ')}"
        puts "Spotify ID: #{song_with_artists.id_on_spotify}"
        puts "Stations: #{song.station_count}"

        recent_airplays = song_with_artists.air_plays.where(broadcasted_at: 24.hours.ago..).includes(:radio_station)
        puts 'Recent airplays:'
        recent_airplays.each do |ap|
          puts "  - #{ap.radio_station.name} at #{ap.broadcasted_at}"
        end
        puts '-' * 40
      end
    end
  end

  desc 'Re-enrich a specific song from Spotify by ID'
  task :re_enrich, [:song_id] => :environment do |_t, args|
    song_id = args[:song_id]
    abort 'Please provide a song ID: rake songs:re_enrich[123]' if song_id.blank?

    song = Song.includes(:artists).find_by(id: song_id)
    abort "Song with ID #{song_id} not found" if song.blank?

    puts "Re-enriching song: #{song.title}"
    puts "Current artists: #{song.artists.map(&:name).join(', ')}"
    puts "Spotify ID: #{song.id_on_spotify}"

    result = song.re_enrich_from_spotify

    if result
      song.reload
      puts "\nAfter re-enrichment:"
      puts "Title: #{song.title}"
      puts "Artists: #{song.artists.map(&:name).join(', ')}"
      puts "Spotify URL: #{song.spotify_song_url}"
      puts 'Done!'
    else
      puts 'Failed to re-enrich song (no Spotify match found)'
    end
  end

  desc 'Re-enrich all suspicious songs from Spotify'
  task fix_suspicious: :environment do
    puts 'Finding and fixing suspicious songs...'

    suspicious_songs = Song.joins(:air_plays)
                         .where(air_plays: { broadcasted_at: 24.hours.ago.. })
                         .group('songs.id')
                         .having('COUNT(DISTINCT air_plays.radio_station_id) >= 5')
                         .having('MAX(air_plays.broadcasted_at) - MIN(air_plays.broadcasted_at) < interval \'30 minutes\'')

    if suspicious_songs.empty?
      puts 'No suspicious songs found.'
      return
    end

    puts "Found #{suspicious_songs.count} suspicious songs"

    suspicious_songs.each do |song|
      song_record = Song.includes(:artists).find(song.id)
      puts "\nProcessing: #{song_record.title} (ID: #{song_record.id})"
      puts "Current artists: #{song_record.artists.map(&:name).join(', ')}"

      result = song_record.re_enrich_from_spotify

      if result
        song_record.reload
        puts "Updated artists: #{song_record.artists.map(&:name).join(', ')}"
      else
        puts 'Could not re-enrich (no Spotify match)'
      end
    end

    puts "\nDone!"
  end

  desc 'Re-enrich songs updated in a time range. Usage: rake songs:re_enrich_range[2024-12-30 12:00,2024-12-30 13:00]'
  task :re_enrich_range, %i[start_time end_time] => :environment do |_t, args|
    start_time = Time.zone.parse(args[:start_time])
    end_time = Time.zone.parse(args[:end_time])

    abort 'Please provide start and end times' if start_time.blank? || end_time.blank?

    songs = Song.joins(:air_plays)
              .where(air_plays: { broadcasted_at: start_time..end_time })
              .distinct

    puts "Found #{songs.count} songs with airplays between #{start_time} and #{end_time}"

    songs.find_each do |song|
      song_record = Song.includes(:artists).find(song.id)
      puts "Processing: #{song_record.title} (ID: #{song_record.id})"

      result = song_record.re_enrich_from_spotify
      if result
        song_record.reload
        puts "  Updated: #{song_record.artists.map(&:name).join(', ')}"
      else
        puts '  Could not re-enrich'
      end
    end

    puts 'Done!'
  end
end
