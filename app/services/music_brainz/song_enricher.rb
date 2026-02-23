# frozen_string_literal: true

module MusicBrainz
  class SongEnricher
    def initialize(song)
      @song = song
    end

    def enrich
      return if @song.blank?
      return if @song.isrcs.blank?
      return if @song.isrcs.size > 1

      isrcs = MusicBrainz::IsrcsFinder.new(@song.isrcs.first).find
      return if isrcs.blank?

      @song.update(isrcs: isrcs)
    end
  end
end
