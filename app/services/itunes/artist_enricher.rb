# frozen_string_literal: true

module Itunes
  class ArtistEnricher
    def initialize(artist)
      @artist = artist
    end

    def enrich
      return if @artist.blank?
      return if @artist.id_on_itunes.present?
      return if @artist.name.blank?

      result = find_on_itunes
      return unless result&.valid_match?

      @artist.update(build_attributes(result))
    end

    private

    def build_attributes(result)
      {
        id_on_itunes: result.id,
        itunes_artist_url: result.itunes_artist_url
      }
    end

    def find_on_itunes
      result = Itunes::ArtistFinder::Result.new(name: @artist.name)
      result.execute
      result
    end
  end
end
