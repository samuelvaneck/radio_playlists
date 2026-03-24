# frozen_string_literal: true

module Itunes
  class SongEnricher
    def initialize(song)
      @song = song
    end

    def enrich
      return if @song.blank?
      return if @song.id_on_itunes.present? && @song.duration_ms.present? && @song.release_date.present?

      result = find_on_itunes
      return unless result&.valid_match?

      attributes = build_attributes(result)
      @song.update(attributes)
    end

    private

    def build_attributes(result)
      attributes = {
        id_on_itunes: result.id,
        itunes_song_url: result.itunes_song_url,
        itunes_artwork_url: result.itunes_artwork_url,
        itunes_preview_url: result.itunes_preview_url
      }
      attributes[:duration_ms] = result.duration_ms if @song.duration_ms.blank? && result.duration_ms.present?
      attributes[:release_date] = result.release_date if @song.release_date.blank? && result.release_date.present?
      attributes
    end

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
