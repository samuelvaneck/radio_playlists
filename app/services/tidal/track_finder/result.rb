# frozen_string_literal: true

module Tidal
  module TrackFinder
    class Result < Base
      attr_reader :track, :artists, :title, :id, :isrc,
                  :tidal_artwork_url, :tidal_song_url,
                  :duration_ms

      def initialize(args)
        super
        @search_artists = args[:artists]
        @search_title = args[:title]
        @isrc_code = args[:isrc]
        @country = args[:country] || DEFAULT_COUNTRY
      end

      def execute
        @track = find_best_match
        return nil if @track.blank?

        @artists = set_artists
        @title = set_title
        @id = set_id
        @isrc = set_isrc
        @tidal_song_url = set_song_url
        @tidal_artwork_url = set_artwork_url
        @duration_ms = set_duration_ms

        @track
      end

      def valid_match?
        return false if @track.blank?

        @track['title_distance'].to_i >= TITLE_SIMILARITY_THRESHOLD
      end

      private

      # Tidal's `/v2/searchResults` endpoint (camelCase, case-sensitive) surfaces
      # the most-played version of each recording with higher popularity scores
      # than `/v2/tracks?filter[isrc]`. The endpoint's `filter` query parameter
      # only accepts INCLUDE/EXCLUDE values (controlling which result-block
      # kinds come back) — not arbitrary field filters — so ISRC narrowing
      # happens client-side. `include=tracks` is the only useful include here:
      # tracks expose their artists via a `relationships.artists.links`
      # sub-resource, not inline data, so we can't compute artist_distance from
      # this response. We rely on Tidal's search ranking to pre-filter to
      # relevant artists, then validate via title distance and ISRC.
      def find_best_match
        query = ERB::Util.url_encode("#{@search_artists} #{@search_title}")
        url = "/v2/searchResults/#{query}?countryCode=#{@country}&include=tracks"
        response = make_request(url)

        return nil if response.blank?

        track_resources = Array(response['included']).select { |r| r['type'] == 'tracks' }
        return nil if track_resources.blank?

        pool = isrc_filtered(track_resources)
        pick_best_search_track(pool)
      end

      # When a song already has an ISRC (Spotify enrichment populated it),
      # narrow the search results to entries with that exact ISRC. Falls back
      # to the full pool when nothing matches — title distance still gates the
      # final selection.
      def isrc_filtered(tracks)
        return tracks if @isrc_code.blank?

        matched = tracks.select { |t| t.dig('attributes', 'isrc') == @isrc_code }
        matched.presence || tracks
      end

      # Score by title, keep ones over the threshold, pick the highest
      # popularity. Popularity alone would land on the wrong song when the
      # artist has multiple hits — searching "Bruno Mars I Just Might"
      # surfaces "Just the Way You Are" with higher popularity than the actual
      # match — so the title gate is required.
      def pick_best_search_track(tracks)
        scored = tracks.filter_map { |t| attach_title_score(t) }
        valid = scored.select { |t| t['title_distance'].to_i >= TITLE_SIMILARITY_THRESHOLD }
        valid.max_by { |t| t.dig('attributes', 'popularity').to_f }
      end

      def attach_title_score(track)
        return nil if track.blank?

        track['title_distance'] = title_distance(track.dig('attributes', 'title'))
        track
      end

      # /searchResults doesn't return track-artist data inline. Leaving artists
      # empty until we either deep-include or fetch the winner's artists via a
      # follow-up call.
      def set_artists
        []
      end

      def set_title
        @track&.dig('attributes', 'title')
      end

      def set_id
        @track&.dig('id')&.to_s
      end

      def set_isrc
        @track&.dig('attributes', 'isrc')
      end

      def set_song_url
        return nil if @id.blank?

        "https://tidal.com/browse/track/#{@id}"
      end

      # Tidal exposes album cover art behind a separate `coverArt` relationship
      # rather than inline on the track or album resource. Skipping for now —
      # would need an extra include or follow-up call to populate.
      def set_artwork_url
        nil
      end

      def set_duration_ms
        iso = @track&.dig('attributes', 'duration')
        return nil if iso.blank?

        ActiveSupport::Duration.parse(iso).to_i * 1000
      rescue ActiveSupport::Duration::ISO8601Parser::ParsingError
        nil
      end
    end
  end
end
