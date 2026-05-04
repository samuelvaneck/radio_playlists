# frozen_string_literal: true

namespace :normalized_title do
  desc 'Backfill normalized_title for all songs without one'
  task backfill: :environment do
    scope = Song.where(normalized_title: nil).where.not(title: [nil, ''])
    total = scope.count
    puts "Backfilling normalized_title for #{total} songs..."

    processed = 0
    scope.find_each(batch_size: 1000) do |song|
      song.update_column(:normalized_title, TitleNormalizable.normalize(song.title)) # rubocop:disable Rails/SkipsModelValidations
      processed += 1
      print "\rProcessed #{processed}/#{total}..." if (processed % 1000).zero?
    end

    puts "\nDone! Backfilled #{processed} song normalized_titles."
  end
end
