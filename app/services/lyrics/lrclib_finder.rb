# frozen_string_literal: true

module Lyrics
  class LrclibFinder < Base
    def find(artist_name:, track_name:, album_name: nil, duration: nil)
      body = get('get', {
        artist_name: artist_name,
        track_name: track_name,
        album_name: album_name,
        duration: duration
      }.compact)
      return if body.blank? || body['instrumental']

      normalize(body)
    end

    def fetch_by_id(id)
      body = get("get/#{id}")
      return if body.blank? || body['instrumental']

      normalize(body)
    end

    private

    def normalize(body)
      id = body['id']
      {
        id: id&.to_s,
        plain_lyrics: body['plainLyrics'],
        track_name: body['trackName'],
        artist_name: body['artistName'],
        album_name: body['albumName'],
        duration: body['duration'],
        source_url: "#{BASE_URL}get/#{id}"
      }
    end
  end
end
