# frozen_string_literal: true

namespace :migrate_isrcs do
  desc 'Migrate existing isrc values to the isrcs array column. Usage: rake migrate_isrcs:run'
  task run: :environment do
    puts 'Migrating isrc to isrcs array...'
    puts '=' * 80

    songs = Song.where.not(isrc: [nil, '']).where(isrcs: [])
    total = songs.count
    migrated = 0

    puts "Found #{total} songs with isrc but empty isrcs array\n\n"

    songs.find_each.with_index do |song, index|
      print "\rProcessing #{index + 1}/#{total}..."

      song.update_columns(isrcs: [song.isrc]) # rubocop:disable Rails/SkipsModelValidations
      migrated += 1
    end

    puts "\n\n#{'=' * 80}"
    puts "Migrated #{migrated} songs."
  end

  desc 'Dry run: Show how many songs would be migrated. Usage: rake migrate_isrcs:dry_run'
  task dry_run: :environment do
    puts 'DRY RUN: Checking songs to migrate...'
    puts '=' * 80

    with_isrc = Song.where.not(isrc: [nil, '']).count
    already_migrated = Song.where.not(isrc: [nil, '']).where.not(isrcs: []).count
    to_migrate = Song.where.not(isrc: [nil, '']).where(isrcs: []).count
    without_isrc = Song.where(isrc: [nil, '']).count

    puts "Total songs with isrc:        #{with_isrc}"
    puts "Already have isrcs populated:  #{already_migrated}"
    puts "To migrate:                    #{to_migrate}"
    puts "Songs without isrc:            #{without_isrc}"
    puts "\nRun 'rake migrate_isrcs:run' to perform the migration."
  end
end
