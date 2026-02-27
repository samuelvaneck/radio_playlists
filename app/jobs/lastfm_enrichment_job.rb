# frozen_string_literal: true

class LastfmEnrichmentJob
  include Sidekiq::Job
  sidekiq_options queue: 'low'

  def self.enqueue_all
    stale_threshold = 30.days.ago

    Artist.where(lastfm_enriched_at: nil).or(Artist.where(lastfm_enriched_at: ...stale_threshold)).find_each do |artist|
      perform_async('Artist', artist.id)
    end

    Song.where(lastfm_enriched_at: nil).or(Song.where(lastfm_enriched_at: ...stale_threshold)).find_each do |song|
      perform_async('Song', song.id)
    end
  end

  def perform(type, id)
    case type
    when 'Artist'
      enrich_artist(id)
    when 'Song'
      enrich_song(id)
    end
  end

  private

  def enrich_artist(artist_id)
    artist = Artist.find_by(id: artist_id)
    return if artist.blank?

    info = Lastfm::ArtistFinder.new.get_full_info(artist.name)
    return if info.blank?

    artist.update(
      lastfm_listeners: info.dig('stats', 'listeners')&.to_i,
      lastfm_playcount: info.dig('stats', 'playcount')&.to_i,
      lastfm_tags: extract_tags(info.dig('tags', 'tag')),
      lastfm_enriched_at: Time.current
    )
  end

  def enrich_song(song_id)
    song = Song.find_by(id: song_id)
    return if song.blank?

    artist_name = song.artists.first&.name
    return if artist_name.blank?

    info = Lastfm::TrackFinder.new.get_info(artist_name: artist_name, track_name: song.title)
    return if info.blank?

    song.update_columns( # rubocop:disable Rails/SkipsModelValidations
      lastfm_listeners: info['listeners']&.to_i,
      lastfm_playcount: info['playcount']&.to_i,
      lastfm_tags: extract_tags(info.dig('toptags', 'tag')),
      lastfm_enriched_at: Time.current
    )
  end

  def extract_tags(tags)
    return [] if tags.blank?

    tags.first(10).filter_map { |tag| tag['name']&.downcase }
  end
end
