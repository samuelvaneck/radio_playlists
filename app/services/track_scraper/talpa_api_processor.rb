# frozen_string_literal: true

class TrackScraper::TalpaApiProcessor < TrackScraper
  def last_played_song
    api_header = { 'x-api-key': ENV['TALPA_API_KEY'] }
    response = make_request(api_header)
    raise StandardError if response.blank?
    raise StandardError, response[:errors] if response[:errors].present?

    track = response.dig(:data, :getStation, :playouts)[0]
    @artist_name = track.dig(:track, :artistName).titleize
    @title = track.dig(:track, :title).titleize
    @broadcasted_at = Time.find_zone('Amsterdam').parse(track[:broadcastDate])
    @isrc_code = track.dig(:track, :isrc)
    true
  rescue StandardError => e
    Rails.logger.info(e.message)
    ExceptionNotifier.notify_new_relic(e)
    false
  end
end
