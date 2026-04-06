# frozen_string_literal: true

class TrackScraper::MytunerApiProcessor < TrackScraper
  REGISTER_URL = 'https://ajax.mytuner-radio.com/ajax/register-widget/'
  PLAYLIST_URL = 'https://ajax.mytuner-radio.com/ajax/get-station-playlist/'

  def last_played_song
    access_token = register_widget
    return false if access_token.blank?

    response = fetch_playlist(access_token)
    return false if response.blank? || !response['success']

    @raw_response = response
    track = most_recent_track(response)
    return false if track.blank?

    @artist_name = track['artist'].titleize
    @title = TitleSanitizer.sanitize(track['title']).titleize
    @broadcasted_at = Time.zone.at(track['start_time'])
    true
  rescue StandardError => e
    Rails.logger.warn("MytunerApiProcessor: #{e.message}")
    ExceptionNotifier.notify(e)
    false
  end

  private

  def register_widget
    response = mytuner_connection.post(REGISTER_URL) do |req|
      req.body = { widget_id: widget_id, params: { radio_id: radio_id } }.to_json
    end
    return nil unless response.success?

    response.body['access_token']
  end

  def fetch_playlist(access_token)
    response = mytuner_connection.post(PLAYLIST_URL) do |req|
      req.body = { access_token: access_token, radio_id: radio_id, single: 'true' }.to_json
    end
    return nil unless response.success?

    response.body
  end

  def most_recent_track(response)
    tracks = response.dig('data', 0)
    return nil if tracks.blank?

    tracks.last
  end

  def mytuner_connection
    @mytuner_connection ||= Faraday.new do |conn|
      conn.headers['Content-Type'] = 'text/plain;charset=UTF-8'
      conn.response :json
    end
  end

  def widget_id
    config['widget_id']
  end

  def radio_id
    config['radio_id']
  end

  def config
    @config ||= JSON.parse(@radio_station.url)
  end
end
