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
