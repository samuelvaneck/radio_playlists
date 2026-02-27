# frozen_string_literal: true

module Lastfm
  class ArtistFinder < Base
    def get_info(artist_name)
      response = make_request(method: 'artist.getinfo', artist: artist_name, autocorrect: 1)
      return nil if response.nil? || response['error'].present?

      response.dig('artist', 'bio')
    end
  end
end
