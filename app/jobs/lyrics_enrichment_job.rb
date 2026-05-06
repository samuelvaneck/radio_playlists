# frozen_string_literal: true

class LyricsEnrichmentJob
  THROTTLE_INTERVAL = 2 # seconds between jobs

  include Sidekiq::Job
  sidekiq_options queue: 'enrichment', retry: 2

  def self.enqueue_all
    return unless enabled?

    index = 0
    enrichable_songs.find_each do |song|
      perform_in((index * THROTTLE_INTERVAL).seconds, song.id)
      index += 1
    end
  end

  def self.enabled?
    ENV['LYRICS_ENRICHMENT_ENABLED'] == 'true'
  end

  def self.enrichable_songs
    week_ago = 7.days.ago
    stale = Lyric::STALE_AFTER.ago

    # Only enrich songs played at least once in the last week, where lyrics are missing or stale.
    # Cheap MVP scope to keep LLM cost predictable.
    Song
      .joins(:air_plays)
      .where(air_plays: { broadcasted_at: week_ago.. })
      .left_joins(:lyric)
      .where('lyrics.id IS NULL OR lyrics.enriched_at IS NULL OR lyrics.enriched_at < ?', stale)
      .distinct
  end

  def perform(song_id)
    return unless self.class.enabled?

    song = Song.find_by(id: song_id)
    return if song.blank?

    artist_name = song.artists.first&.name
    return if artist_name.blank?

    lyrics_data = Lyrics::LrclibFinder.new.find(
      artist_name: artist_name,
      track_name: song.title,
      duration: song.duration_ms ? (song.duration_ms / 1000.0).round : nil
    )
    return if lyrics_data.blank? || lyrics_data[:plain_lyrics].blank?

    sentiment = Llm::LyricsSentimentAnalyzer.new(lyrics: lyrics_data[:plain_lyrics]).analyze
    return if sentiment.blank?

    upsert_lyric!(song, lyrics_data, sentiment)
  end

  private

  def upsert_lyric!(song, lyrics_data, sentiment)
    lyric = song.lyric || song.build_lyric
    lyric.assign_attributes(
      sentiment: sentiment[:sentiment],
      themes: sentiment[:themes],
      language: sentiment[:language],
      source: 'lrclib',
      source_id: lyrics_data[:id],
      source_url: lyrics_data[:source_url],
      enriched_at: Time.current
    )
    lyric.save!
  end
end
