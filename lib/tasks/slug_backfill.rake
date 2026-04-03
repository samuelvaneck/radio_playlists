# frozen_string_literal: true

namespace :slug do
  desc 'Backfill slugs for all songs without a slug'
  task backfill_songs: :environment do
    total = Song.where(slug: nil).count
    puts "Backfilling slugs for #{total} songs..."

    processed = 0
    Song.where(slug: nil).find_each do |song|
      song.send(:set_slug)
      song.update_column(:slug, song.slug) # rubocop:disable Rails/SkipsModelValidations
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
      artist.send(:set_slug)
      artist.update_column(:slug, artist.slug) # rubocop:disable Rails/SkipsModelValidations
      processed += 1
      print "\rProcessed #{processed}/#{total}..." if (processed % 1000).zero?
    end

    puts "\nDone! Backfilled #{processed} artist slugs."
  end

  desc 'Backfill slugs for all songs and artists without a slug'
  task backfill_all: %i[backfill_songs backfill_artists]
end
