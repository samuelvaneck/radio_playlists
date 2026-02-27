# frozen_string_literal: true

module Lastfm
  class ArtistFinder < Base
    def get_info(artist_name)
      response = make_request(method: 'artist.getinfo', artist: artist_name, autocorrect: 1)
      return nil if response.nil? || response['error'].present?

      response.dig('artist', 'bio')
    end

    def get_full_info(artist_name)
      response = make_request(method: 'artist.getinfo', artist: artist_name, autocorrect: 1)
      return nil if response.nil? || response['error'].present?

      response['artist']
    end

    def get_top_tags(artist_name)
      response = make_request(method: 'artist.gettoptags', artist: artist_name, autocorrect: 1)
      return nil if response.nil? || response['error'].present?

      response.dig('toptags', 'tag')
    end
  end
end
