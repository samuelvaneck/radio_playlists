# frozen_string_literal: true

class TrackScraper::QmusicApiProcessor < TrackScraper
  def last_played_song
    response = make_request
    return false if response.blank?

    track = response[:played_tracks][0]
    @broadcasted_at = Time.find_zone('Amsterdam').parse(track[:played_at])
    @artist_name = track[:artist][:name].titleize
    @title = track[:title].titleize
    @spotify_url = track[:spotify_url]
    @youtube_id = track.dig(:videos, 0, :id)
    true
  rescue StandardError => e
    Rails.logger.info(e.message)
    ExceptionNotifier.notify_new_relic(e)
    nil
  end
end
