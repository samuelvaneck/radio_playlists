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

        @track['artist_distance'].to_i >= ARTIST_SIMILARITY_THRESHOLD &&
          @track['title_distance'].to_i >= TITLE_SIMILARITY_THRESHOLD
      end

      private

      # Tidal's `/v2/searchresults` endpoint surfaces the most-played track per
      # recording (the version users actually listen to), which gives us higher
      # popularity scores and better matches than `/v2/tracks?filter[isrc]`.
      # `filter` here only takes INCLUDE/EXCLUDE values (controls which result
      # blocks come back), not arbitrary field filters — so when an ISRC is
      # available we narrow client-side after the search returns.
      def find_best_match
        query = ERB::Util.url_encode("#{@search_artists} #{@search_title}")
        url = "/v2/searchresults/#{query}?countryCode=#{@country}&include=tracks,artists"
        response = make_request(url)

        return nil if response.blank?

        included = Array(response['included'])
        track_resources = included.select { |r| r['type'] == 'tracks' }
        return nil if track_resources.blank?

        index = build_included_index(included)
        pool = isrc_filtered(track_resources)
        pick_best_search_track(pool, index)
      end

      # When a song already has an ISRC (Spotify enrichment populated it), narrow
      # the search results to entries with that exact ISRC. Falls back to the
      # full pool if the search didn't surface a matching ISRC — better to
      # validate via artist/title distance than to return nothing.
      def isrc_filtered(tracks)
        return tracks if @isrc_code.blank?

        matched = tracks.select { |t| t.dig('attributes', 'isrc') == @isrc_code }
        matched.presence || tracks
      end

      # Score every candidate (artist + title), keep ones over the thresholds,
      # then pick the highest popularity. Popularity is the deciding signal here
      # because /searchresults already pre-filters to relevant matches.
      def pick_best_search_track(tracks, index)
        scored = tracks.filter_map { |t| attach_resources(t, index) }
        valid = scored.select do |t|
          t['artist_distance'].to_i >= ARTIST_SIMILARITY_THRESHOLD &&
            t['title_distance'].to_i >= TITLE_SIMILARITY_THRESHOLD
        end
        valid.max_by { |t| t.dig('attributes', 'popularity').to_f }
      end

      # Attach artist resources and compute JaroWinkler distances. Mutates
      # `track` so the winner can carry its scores into the setter chain.
      def attach_resources(track, index)
        return nil if track.blank?

        track['artist_resources'] = artist_resources_via_index(track, index)
        track['artist_distance'] = artist_distance(combined_artist_name(track))
        track['title_distance'] = title_distance(track.dig('attributes', 'title'))
        track
      end

      # Build a `{ [type, id] => resource }` lookup so member-resolution stays
      # O(1) instead of scanning `included` per candidate.
      def build_included_index(included)
        return {} if included.blank?

        Array(included).index_by { |r| [r['type'], r['id']] }
      end

      def artist_resources_via_index(track, index)
        ids = Array(track.dig('relationships', 'artists', 'data')).pluck('id')
        ids.filter_map { |id| index[['artists', id]] }
      end

      def combined_artist_name(track)
        names = Array(track['artist_resources']).filter_map { |a| a.dig('attributes', 'name') }
        names.join(' & ')
      end

      def set_artists
        Array(@track&.dig('artist_resources')).map do |resource|
          { 'name' => resource.dig('attributes', 'name'), 'id' => resource['id'] }
        end
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
