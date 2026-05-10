# frozen_string_literal: true

namespace :timeline do
  desc 'Print a Wikidata + MusicBrainz timeline for an artist as JSON'
  task :fetch, %i[artist_id language] => :environment do |_t, args|
    artist_id = args[:artist_id]
    if artist_id.blank?
      $stdout.puts 'Usage: bundle exec rake timeline:fetch[<artist_id>,<language>]'
      next
    end

    artist = Artist.find(artist_id)
    payload = ArtistTimelineBuilder.new(artist, language: args[:language] || 'en').()
    $stdout.puts JSON.pretty_generate(payload)
  end

  desc 'Enqueue ArtistTimelineEnrichmentJob for every artist with a MusicBrainz ID'
  task backfill: :environment do
    $stdout.puts 'Enqueueing artists for timeline backfill...'
    ArtistTimelineEnrichmentJob.enqueue_all
    $stdout.puts 'Done.'
  end

  desc 'Enqueue ArtistTimelineEnrichmentJob for artists with stale or missing timelines (default 30 days)'
  task :refresh_stale, [:days] => :environment do |_t, args|
    days = (args[:days].presence || 30).to_i
    $stdout.puts "Enqueueing artists with timelines older than #{days} days..."
    ArtistTimelineEnrichmentJob.enqueue_stale(after: days.days)
    $stdout.puts 'Done.'
  end
end
