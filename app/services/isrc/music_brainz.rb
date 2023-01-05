# frozen_string_literal: true

class Isrc::MusicBrainz < Isrc
  ENDPOINT = 'https://musicbrainz.org/ws/2/recording/'

  def search
    make_request
  end

  def make_request
    url = URI("#{ENDPOINT}?query=isrc:#{@args[:isrc]}&fmt=json")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request['Content-Type'] = 'application/json'
    request['User-Agent'] = 'RadioPlaylistsRuntime/1.0.0 (https://playlists.samuelvaneck.com)'
    response = https.request(request)

    handle_response(response)
  end

  def handle_response(response)
    if response.try(:code) == '200'
      recording = JSON.parse(response.body)['recordings'][0]
      @title = recording['title']
      @artist_names = recording['artist-credit'].map { |artist| artist['name'] }
      true
    else
      Rails.logger.error JSON(response.read_body)
      false
    end
  end
end
