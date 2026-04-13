# frozen_string_literal: true

module SongImporter::Concerns
  module TrackFinding
    extend ActiveSupport::Concern

    private

    def track
      @track ||= spotify_track_if_valid || itunes_track_if_valid || deezer_track_if_valid || llm_cleaned_track
    end

    def llm_import_enabled?
      ENV.fetch('LLM_IMPORT_ENABLED', 'true') == 'true'
    end

    def spotify_track_if_valid
      result = spotify_track
      return result if result&.valid_match?
      return nil unless llm_import_enabled?

      # Try alternative search queries when Spotify returned no results at all
      if no_spotify_results?(result)
        alt_result = spotify_track_with_alternative_queries
        return alt_result if alt_result&.valid_match?
      end

      # Ask GPT to validate borderline title matches (60-69% title similarity, artist already passes)
      return llm_validated_spotify_track(result) if borderline_match?(result)

      nil
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

    # Feature 5: Generate alternative search queries via LLM when Spotify returned no results
    def spotify_track_with_alternative_queries
      service = Llm::AlternativeSearchQueries.new(artist_name: artist_name, title: title)
      alternatives = service.generate
      @import_logger.log_llm(action: 'alternative_search_queries', raw_response: service.raw_response)
      return nil if alternatives.blank?

      alternatives.each do |alt|
        alt_result = Spotify::TrackFinder::Result.new(artists: alt['artist'], title: alt['title'])
        alt_result.execute
        next unless alt_result.valid_match?

        Rails.logger.info("[LLM] Alternative query matched: '#{alt['artist']} - #{alt['title']}'")
        @import_logger.log_spotify(alt_result)
        return alt_result
      end
      nil
    end

    def no_spotify_results?(result)
      return true if result.blank?

      result.track.blank? && result.spotify_query_result&.dig('tracks', 'items').blank?
    end

    # Feature 4: Validate borderline matches where title similarity is 60-69% but artist passes
    def borderline_match?(result)
      return false if result.blank? || result.track.blank?

      result.matched_artist_distance.to_i >= Spotify::Base::ARTIST_SIMILARITY_THRESHOLD &&
        Llm::BorderlineMatchValidator::BORDERLINE_TITLE_RANGE.cover?(result.matched_title_distance.to_i)
    end

    def llm_validated_spotify_track(result)
      matched_artist = result.artists&.filter_map { |a| a&.dig('name') }&.join(', ')
      validator = Llm::BorderlineMatchValidator.new(
        scraped_title: title,
        scraped_artist: artist_name,
        matched_title: result.title,
        matched_artist: matched_artist
      )
      is_same = validator.same_song?
      @import_logger.log_llm(action: 'borderline_match_validation', raw_response: validator.raw_response)
      return nil unless is_same

      Rails.logger.info("[LLM] Borderline match validated: '#{title}' ≈ '#{result.title}'")
      result
    end

    # Feature 1: Clean up artist/title via LLM and retry Spotify as last resort
    def llm_cleaned_track
      return nil unless llm_import_enabled?

      service = Llm::TrackNameCleaner.new(artist_name: artist_name, title: title)
      cleaned = service.clean
      @import_logger.log_llm(action: 'track_name_cleanup', raw_response: service.raw_response)
      return nil if cleaned.blank?

      Rails.logger.info("[LLM] Track name cleaned: '#{artist_name}' → '#{cleaned['artist']}', '#{title}' → '#{cleaned['title']}'")
      cleaned_result = Spotify::TrackFinder::Result.new(artists: cleaned['artist'], title: cleaned['title'])
      cleaned_result.execute
      return nil unless cleaned_result.valid_match?

      @import_logger.log_spotify(cleaned_result)
      cleaned_result
    end
  end
end
