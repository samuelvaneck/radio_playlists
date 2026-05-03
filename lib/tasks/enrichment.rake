# frozen_string_literal: true

namespace :enrichment do
  desc 'Backfill album_name for songs with Spotify IDs'
  task backfill_album_names: :environment do
    songs = Song.where(album_name: nil).where.not(id_on_spotify: [nil, ''])
    total = songs.count
    puts "Enqueueing #{total} songs for album_name backfill..."

    songs.find_each do |song|
      Spotify::SongEnricher.new(song, force: true).enrich
    end

    puts 'Done.'
  end

  desc 'Backfill Spotify popularity and followers for artists'
  task backfill_artist_spotify_metrics: :environment do
    artists = Artist.where(spotify_popularity: nil).where.not(id_on_spotify: [nil, ''])
    total = artists.count
    puts "Enqueueing #{total} artists for Spotify metrics backfill..."

    artists.find_each do |artist|
      ArtistEnrichmentJob.perform_async(artist.id)
    end

    puts 'Done.'
  end

  desc 'Backfill artist nationality from Wikidata'
  task backfill_artist_nationality: :environment do
    puts 'Enqueueing artists for nationality backfill...'
    ArtistEnrichmentJob.enqueue_all
    puts 'Done.'
  end

  desc 'Backfill aka_names from MusicBrainz (synchronous, respects 1 req/sec rate limit)'
  task backfill_artist_aka_names: :environment do
    scope = Artist.where(aka_names_checked_at: nil).where.not(name: [nil, ''])
    total = scope.count
    puts "Backfilling aka_names for #{total} artists..."

    processed = 0
    failed = 0
    scope.find_each do |artist|
      success = MusicBrainz::ArtistAliasFetcher.new(artist).()
      success ? (processed += 1) : (failed += 1)
      done = processed + failed
      print "\rProcessed #{done}/#{total} (failed: #{failed})..." if (done % 10).zero?
    end

    puts "\nDone! Backfilled #{processed} artists, #{failed} did not match a MusicBrainz record."
  end

  desc 'Backfill Tidal/Deezer/iTunes IDs for artists missing one or more'
  task backfill_artist_external_ids: :environment do
    scope = Artist.where(id_on_tidal: nil).or(Artist.where(id_on_deezer: nil)).or(Artist.where(id_on_itunes: nil))
    total = scope.count
    puts "Enqueueing #{total} artists for external IDs backfill..."

    scope.find_each { |artist| ArtistExternalIdsEnrichmentJob.perform_async(artist.id) }

    puts 'Done.'
  end

  desc 'Backfill Last.fm data for artists and songs'
  task backfill_lastfm: :environment do
    puts 'Enqueueing artists and songs for Last.fm backfill...'
    LastfmEnrichmentJob.enqueue_all
    puts 'Done.'
  end

  desc 'Run all enrichment backfills'
  task backfill_all: :environment do
    %w[
      enrichment:backfill_album_names
      enrichment:backfill_artist_spotify_metrics
      enrichment:backfill_artist_nationality
      enrichment:backfill_lastfm
    ].each do |task|
      puts "Running #{task}..."
      Rake::Task[task].invoke
    end
  end
end
