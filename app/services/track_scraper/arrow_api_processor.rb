# frozen_string_literal: true

class TrackScraper::ArrowApiProcessor < TrackScraper
  def last_played_song
    response = make_request
    return false if response.blank?

    @raw_response = response
    track = response[:current]
    return false if track.blank? || track[:artist].blank? || commercial?(track)

    @artist_name = track[:artist].titleize
    @title = TitleSanitizer.sanitize(track[:title]).titleize
    @broadcasted_at = Time.zone.at(track[:startTime] / 1000)
    true
  rescue StandardError => e
    Rails.logger.warn("ArrowApiProcessor: #{e.message}")
    ExceptionNotifier.notify(e)
    false
  end

  private

  def commercial?(track)
    track[:category].to_s.downcase.include?('commercials')
  end
end
