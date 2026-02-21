# frozen_string_literal: true

module MusicBrainz
  class SongEnricher
    def initialize(song)
      @song = song
    end

    def enrich
      return if @song.blank?
      return if @song.isrc.blank?
      return if @song.isrcs.present?

      isrcs = MusicBrainz::IsrcsFinder.new(@song.isrc).find
      return if isrcs.blank?

      @song.update(isrcs: isrcs)
    end
  end
end
