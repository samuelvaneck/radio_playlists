# frozen_string_literal: true

module Deezer
  class ArtistEnricher
    def initialize(artist)
      @artist = artist
    end

    def enrich
      return if @artist.blank?
      return if @artist.id_on_deezer.present?
      return if @artist.name.blank?

      result = find_on_deezer
      return unless result&.valid_match?

      @artist.update(build_attributes(result))
    end

    private

    def build_attributes(result)
      {
        id_on_deezer: result.id,
        deezer_artist_url: result.deezer_artist_url,
        deezer_artwork_url: result.deezer_artwork_url
      }
    end

    def find_on_deezer
      result = Deezer::ArtistFinder::Result.new(name: @artist.name)
      result.execute
      result
    end
  end
end
