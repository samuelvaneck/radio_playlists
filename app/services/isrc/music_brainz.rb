# frozen_string_literal: true

class Isrc::MusicBrainz < Isrc
  ENDPOINT = 'https://musicbrainz.org/ws/2/recording/'

  def data
    url = URI("#{ENDPOINT}?query=isrc:#{@args[:isrc_code]}&fmt=json")
    response = make_request(url:, headers: request_headers)
    handle_response(response)
  end

  private

  def request_headers
    headers = {}
    headers['Content-Type'] = 'application/json'
    headers['User-Agent'] = 'RadioPlaylistsRuntime/1.0.0 (https://playlists.samuelvaneck.com)'
    headers
  end

  def handle_response(response)
    if response.try(:code) == '200'
      recording = JSON.parse(response.body)['recordings'][0]
      @title = recording['title']
      @artist_names = recording['artist-credit'].map { |artist| artist['name'] }.join(' - ')
      true
    else
      Rails.logger.error JSON(response.read_body)
      false
    end
  end
end
