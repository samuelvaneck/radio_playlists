# frozen_string_literal: true

namespace :slug do
  desc 'Backfill slugs for all songs without a slug'
  task backfill_songs: :environment do
    total = Song.where(slug: nil).count
    puts "Backfilling slugs for #{total} songs..."

    processed = 0
    Song.where(slug: nil).find_each do |song|
      song.update_slug
      processed += 1
      print "\rProcessed #{processed}/#{total}..." if (processed % 1000).zero?
    end

    puts "\nDone! Backfilled #{processed} song slugs."
  end

  desc 'Backfill slugs for all artists without a slug'
  task backfill_artists: :environment do
    total = Artist.where(slug: nil).count
    puts "Backfilling slugs for #{total} artists..."

    processed = 0
    Artist.where(slug: nil).find_each do |artist|
      artist.update_slug
      processed += 1
      print "\rProcessed #{processed}/#{total}..." if (processed % 1000).zero?
    end

    puts "\nDone! Backfilled #{processed} artist slugs."
  end

  desc 'Backfill slugs for all songs and artists without a slug'
  task backfill_all: %i[backfill_songs backfill_artists]

  desc 'Regenerate slugs that were built from empty parameterize output (non-Latin titles)'
  task repair_empty: :environment do
    song_scope = Song.where("slug = '' OR slug ~ '^-[0-9]+$'")
    artist_scope = Artist.where("slug = '' OR slug ~ '^-[0-9]+$'")

    song_total = song_scope.count
    artist_total = artist_scope.count
    puts "Repairing #{song_total} songs and #{artist_total} artists with broken slugs..."

    repair_records(song_scope, 'songs')
    repair_records(artist_scope, 'artists')
  end

  def repair_records(scope, label)
    processed = 0
    total = scope.count
    scope.find_each do |record|
      record.update_slug
      processed += 1
      print "\rRepaired #{processed}/#{total} #{label}..." if (processed % 100).zero?
    end
    puts "\nDone! Repaired #{processed} #{label}."
  end
end
