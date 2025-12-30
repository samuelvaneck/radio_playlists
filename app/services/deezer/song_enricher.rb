# frozen_string_literal: true

module Deezer
  class SongEnricher
    def initialize(song)
      @song = song
    end

    def enrich
      return if @song.blank?
      return if @song.id_on_deezer.present?

      result = find_on_deezer
      return unless result&.valid_match?

      @song.update(
        id_on_deezer: result.id,
        deezer_song_url: result.deezer_song_url,
        deezer_artwork_url: result.deezer_artwork_url,
        deezer_preview_url: result.deezer_preview_url
      )
    end

    private

    def find_on_deezer
      result = Deezer::TrackFinder::Result.new(
        artists: @song.artists.map(&:name).join(' '),
        title: @song.title,
        isrc: @song.isrc
      )
      result.execute
      result
    end
  end
end
