# frozen_string_literal: true

class ChartSongEnrichmentJob
  THROTTLE_INTERVAL = 2 # seconds between enqueued jobs

  include Sidekiq::Job
  sidekiq_options queue: 'enrichment'

  def perform
    chart = Chart.latest_song_chart
    return if chart.blank?

    song_ids = chart.chart_positions.where(positianable_type: 'Song').pluck(:positianable_id)
    stale_songs = Song.where(id: song_ids).where(lastfm_enriched_at: nil)
                    .or(Song.where(id: song_ids).where(lastfm_enriched_at: ...1.day.ago))

    stale_songs.find_each.with_index do |song, index|
      LastfmEnrichmentJob.perform_in((index * THROTTLE_INTERVAL).seconds, 'Song', song.id)
      song.enrich_with_spotify(force: true)
    end
  end
end
