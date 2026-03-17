# frozen_string_literal: true

module SongImporter::Concerns
  module TrackFinding
    extend ActiveSupport::Concern

    private

    def track
      @track ||= spotify_track_if_valid || itunes_track_if_valid || deezer_track_if_valid
    end

    def spotify_track_if_valid
      result = spotify_track
      result&.valid_match? ? result : nil
    end

    def itunes_track_if_valid
      result = itunes_track
      result&.valid_match? ? result : nil
    end

    def deezer_track_if_valid
      result = deezer_track
      result&.valid_match? ? result : nil
    end

    def spotify_track
      @spotify_track ||= begin
        result = TrackExtractor::SpotifyTrackFinder.new(played_song: @played_song).find
        @import_logger.log_spotify(result) if result
        result
      end
    end

    def deezer_track
      @deezer_track ||= begin
        result = TrackExtractor::DeezerTrackFinder.new(played_song: @played_song).find
        @import_logger.log_deezer(result) if result&.valid_match?
        result
      end
    end

    def itunes_track
      @itunes_track ||= begin
        result = TrackExtractor::ItunesTrackFinder.new(played_song: @played_song).find
        @import_logger.log_itunes(result) if result&.valid_match?
        result
      end
    end
  end
end
