# frozen_string_literal: true

class TrackScraper::ArrowApiProcessor < TrackScraper
  def last_played_song
    response = make_request
    return false if response.blank?

    @raw_response = response
    return false unless music?(response)
    return false if response['artist'].blank? || response['title'].blank?

    @artist_name = response['artist'].titleize
    @title = TitleSanitizer.sanitize(response['title']).titleize
    @broadcasted_at = Time.zone.at(response['timestamp'])
    true
  rescue StandardError => e
    Rails.logger.warn("ArrowApiProcessor: #{e.message}")
    ExceptionNotifier.notify(e)
    false
  end

  private

  def music?(response)
    return false if response['hasCurrentTrack'] == false

    state = response['state'].to_s.downcase
    state.blank? || state == 'music'
  end
end
