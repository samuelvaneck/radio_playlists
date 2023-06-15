# frozen_string_literal: true

module Spotify
  class Artist < Base
    attr_reader :id_on_spotify

    def initialize(args)
      super
      @id_on_spotify = args[:id_on_spotify]
    end

    def info
      make_request(url)
    end

    private

    def url
      URI("https://api.spotify.com/v1/artists/#{@id_on_spotify}")
    end
  end
end
