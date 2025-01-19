# frozen_string_literal: true

class TrackScraper::QmusicApiProcessor < TrackScraper
  def last_played_song
    json = JSON(make_request)
    return false if json.blank?

    track = json['played_tracks'][0]
    @broadcasted_at = Time.find_zone('Amsterdam').parse(track['played_at'])
    @artist_name = track['artist']['name'].titleize
    @title = track['title'].titleize
    @spotify_url = track['spotify_url']
    true
  end

  def make_request
    uri = URI @radio_station.url
    api_header = { 'x-api-key': ENV['QMUSIC_API_KEY'] }
    response = Net::HTTP.get_response(uri, api_header)
    JSON.parse(response.body)
  end
end
