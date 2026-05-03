# frozen_string_literal: true

module Tidal
  class ArtistEnricher
    def initialize(artist)
      @artist = artist
    end

    def enrich
      return if @artist.blank?
      return if @artist.id_on_tidal.present?
      return if @artist.name.blank?

      result = find_on_tidal
      return unless result&.valid_match?

      @artist.update(build_attributes(result))
    end

    private

    def build_attributes(result)
      {
        id_on_tidal: result.id,
        tidal_artist_url: result.tidal_artist_url
      }
    end

    def find_on_tidal
      result = Tidal::ArtistFinder::Result.new(name: @artist.name)
      result.execute
      result
    end
  end
end
