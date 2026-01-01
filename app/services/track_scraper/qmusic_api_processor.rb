# frozen_string_literal: true

class TrackScraper::QmusicApiProcessor < TrackScraper
  def last_played_song
    response = make_request
    raise StandardError if response.blank?

    @raw_response = response
    track = response[:played_tracks][0]
    return false if track.blank?

    @broadcasted_at = Time.find_zone('Amsterdam')&.parse(track[:played_at])
    @artist_name = track.dig(:artist, :name).titleize
    @title = TitleSanitizer.sanitize(track[:title]).titleize
    @spotify_url = track[:spotify_url]
    @youtube_id = track.dig(:videos, 0, :id)
    @website_url = track.dig(:artist, :website_url)
    @instagram_url = track.dig(:artist, :instagram_url)
    true
  rescue StandardError => e
    Rails.logger.info(e.message)
    ExceptionNotifier.notify_new_relic(e)
    false
  end
end
