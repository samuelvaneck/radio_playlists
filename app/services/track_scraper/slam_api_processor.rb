# frozen_string_literal: true

class TrackScraper::SlamApiProcessor < TrackScraper
  def last_played_song
    response = make_request
    raise StandardError if response.blank?

    track = response[:data][:song]
    return false if track.blank?

    @artist_name = track[:artist].titleize
    @title = track[:title].titleize
    @broadcasted_at = Time.zone.now
    true
  rescue StandardError => e
    Rails.logger.info(e.message)
    ExceptionNotifier.notify_new_relic(e)
    false
  end
end
