# frozen_string_literal: true

namespace :lyrics do
  desc 'Enqueue LyricsEnrichmentJob for recently-played songs missing or stale lyrics. ' \
       'Requires LYRICS_ENRICHMENT_ENABLED=true. Usage: rake lyrics:backfill'
  task backfill: :environment do
    unless LyricsEnrichmentJob.enabled?
      $stdout.puts 'Skipping: LYRICS_ENRICHMENT_ENABLED is not set to true'
      next
    end

    count = LyricsEnrichmentJob.enrichable_songs.count
    $stdout.puts "Enqueuing lyrics enrichment for #{count} songs..."
    LyricsEnrichmentJob.enqueue_all
    $stdout.puts 'Done.'
  end
end
