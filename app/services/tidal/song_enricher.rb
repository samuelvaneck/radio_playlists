# frozen_string_literal: true

module Tidal
  class SongEnricher
    def initialize(song)
      @song = song
    end

    def enrich
      return if @song.blank?
      return if @song.id_on_tidal.present?

      result = find_on_tidal
      return unless result&.valid_match?

      @song.update(build_attributes(result))
    end

    private

    def build_attributes(result)
      {
        id_on_tidal: result.id,
        tidal_song_url: result.tidal_song_url,
        tidal_artwork_url: result.tidal_artwork_url
      }
    end

    def find_on_tidal
      result = Tidal::TrackFinder::Result.new(
        artists: @song.artists.map(&:name).join(' '),
        title: @song.title,
        isrc: @song.isrcs&.first
      )
      result.execute
      result
    end
  end
end
