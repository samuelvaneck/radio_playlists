# frozen_string_literal: true

namespace :music_profile do
  desc 'Backfill music profiles for existing songs with Spotify IDs'
  task backfill: :environment do
    total = Song.with_id_on_spotify.left_joins(:music_profile).where(music_profiles: { id: nil }).count
    processed = 0

    puts "Enqueuing #{total} songs for music profile creation..."

    Song.with_id_on_spotify
      .left_joins(:music_profile)
      .where(music_profiles: { id: nil })
      .find_each do |song|
        MusicProfileJob.perform_async(song.id)
        processed += 1
        puts "Enqueued #{processed}/#{total}" if (processed % 1000).zero?
      end

    puts "Enqueued #{total} songs for music profile creation"
  end

  desc 'Backfill music profiles synchronously (for smaller datasets or debugging)'
  task backfill_sync: :environment do
    total = Song.with_id_on_spotify.left_joins(:music_profile).where(music_profiles: { id: nil }).count
    processed = 0
    failed = 0

    puts "Processing #{total} songs synchronously..."

    Song.with_id_on_spotify
      .left_joins(:music_profile)
      .where(music_profiles: { id: nil })
      .find_each do |song|
        MusicProfileJob.new.perform(song.id)
        processed += 1
        puts "Processed #{processed}/#{total}" if (processed % 100).zero?
      rescue StandardError => e
        failed += 1
        puts "Failed for song #{song.id}: #{e.message}"
      end

    puts "Completed: #{processed - failed} succeeded, #{failed} failed"
  end

  desc 'Show statistics for music profiles'
  task stats: :environment do
    total_songs = Song.count
    songs_with_spotify = Song.with_id_on_spotify.count
    songs_with_profile = MusicProfile.count

    puts "Total songs: #{total_songs}"
    puts "Songs with Spotify ID: #{songs_with_spotify}"
    puts "Songs with music profile: #{songs_with_profile}"
    puts "Songs needing profile: #{songs_with_spotify - songs_with_profile}"
  end
end
