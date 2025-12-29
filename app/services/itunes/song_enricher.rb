# frozen_string_literal: true

module Itunes
  class SongEnricher
    def initialize(song)
      @song = song
    end

    def enrich
      return if @song.blank?
      return if @song.id_on_itunes.present?

      result = find_on_itunes
      return unless result&.valid_match?

      # rubocop:disable Rails/SkipsModelValidations
      # Use update_columns to bypass callbacks and prevent infinite loop
      @song.update_columns(
        id_on_itunes: result.id,
        itunes_song_url: result.itunes_song_url,
        itunes_artwork_url: result.itunes_artwork_url,
        itunes_preview_url: result.itunes_preview_url
      )
      # rubocop:enable Rails/SkipsModelValidations
    end

    private

    def find_on_itunes
      result = Itunes::TrackFinder::Result.new(
        artists: @song.artists.map(&:name).join(' '),
        title: @song.title
      )
      result.execute
      result
    end
  end
end
