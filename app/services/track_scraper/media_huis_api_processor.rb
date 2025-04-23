# frozen_string_literal: true

class TrackScraper::MediaHuisApiProcessor < TrackScraper
  def last_played_song
    response = make_request
    raise StandardError if response.blank?

    track = response[:tracks][0]
    return false if track.blank?

    @artist_name = track[:artist].titleize
    @title = track[:title].titleize
    @broadcasted_at = Time.zone.parse(track[:createdAt])
    @spotify_url = track[:spotifyLink]
    true
  rescue StandardError => e
    Rails.logger.info(e.message)
    ExceptionNotifier.notify_new_relic(e)
    false
  end
end
