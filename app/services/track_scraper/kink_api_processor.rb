# frozen_string_literal: true

class TrackScraper::KinkApiProcessor < TrackScraper
  def last_played_song
    response = make_request
    raise StandardError if response.blank?

    track = response[:extended][:kink]
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
