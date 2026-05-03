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

      def find_best_match
        if @isrc_code.present?
          isrc_result = search_by_isrc
          if isrc_result.present? &&
             isrc_result['artist_distance'].to_i >= ARTIST_SIMILARITY_THRESHOLD &&
             isrc_result['title_distance'].to_i >= TITLE_SIMILARITY_THRESHOLD
            return isrc_result
          end
        end

        search_by_query
      end

      def search_by_isrc
        url = "/v2/tracks?countryCode=#{@country}&filter%5Bisrc%5D=#{ERB::Util.url_encode(@isrc_code)}" \
              '&include=artists,albums,albums.artists'
        response = make_request(url)

        return nil if response.blank? || response['data'].blank?

        index = build_included_index(response['included'])
        winner = pick_isrc_winner(response['data'], index)
        return nil if winner.blank?

        attach_resources(winner, index)
      end

      # Tidal returns one track resource per album the recording appears on (singles,
      # compilations, deluxe editions). Prefer entries where the album credits the
      # same artist as the track itself — that rules out "Various Artists" comps.
      # Tiebreak by Tidal's track popularity so we land on the most-played version.
      # Cheap album-artist filter runs first so we only pay for resource lookup +
      # JaroWinkler on the final winner, not on all 20 candidates.
      def pick_isrc_winner(tracks, index)
        primary = tracks.select { |t| album_artist_matches_track_artist?(t, index) }
        (primary.presence || tracks).max_by { |t| t.dig('attributes', 'popularity').to_f }
      end

      def album_artist_matches_track_artist?(track, index)
        track_artist_ids = track_artist_ids_for(track)
        return false if track_artist_ids.blank?

        album_artist_ids = album_artist_ids_via_index(track, index)
        album_artist_ids.present? && track_artist_ids.intersect?(album_artist_ids)
      end

      def search_by_query
        query = ERB::Util.url_encode("#{@search_artists} #{@search_title}")
        url = "/v2/searchresults/#{query}?countryCode=#{@country}&include=tracks,artists,albums"
        response = make_request(url)

        return nil if response.blank?

        included = Array(response['included'])
        track_resources = included.select { |r| r['type'] == 'tracks' }
        return nil if track_resources.blank?

        index = build_included_index(included)
        scored = track_resources.filter_map { |t| attach_resources(t, index) }
        valid = scored.select do |t|
          t['artist_distance'].to_i >= ARTIST_SIMILARITY_THRESHOLD &&
            t['title_distance'].to_i >= TITLE_SIMILARITY_THRESHOLD
        end
        valid.max_by { |t| [t['artist_distance'], t['title_distance']].min }
      end

      # Attach related artist/album resources and compute JaroWinkler distances.
      # Mutates `track` once — only ever called on the winning candidate, so we
      # don't pay JW twice for tracks we'll throw away.
      def attach_resources(track, index)
        return nil if track.blank?

        track['artist_resources'] = artist_resources_via_index(track, index)
        track['album_resource'] = album_resource_via_index(track, index)
        track['artist_distance'] = artist_distance(combined_artist_name(track))
        track['title_distance'] = title_distance(track.dig('attributes', 'title'))
        track
      end

      # Build a `{ [type, id] => resource }` lookup so member-resolution stays O(1)
      # instead of scanning `included` (~20 entries) per candidate (~20 candidates).
      def build_included_index(included)
        return {} if included.blank?

        Array(included).index_by { |r| [r['type'], r['id']] }
      end

      def track_artist_ids_for(track)
        Array(track.dig('relationships', 'artists', 'data')).pluck('id')
      end

      def album_artist_ids_via_index(track, index)
        album = album_resource_via_index(track, index)
        Array(album&.dig('relationships', 'artists', 'data')).pluck('id')
      end

      def artist_resources_via_index(track, index)
        track_artist_ids_for(track).filter_map { |id| index[['artists', id]] }
      end

      def album_resource_via_index(track, index)
        album_id = track.dig('relationships', 'albums', 'data')&.first&.dig('id')
        return nil if album_id.blank?

        index[['albums', album_id]]
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

      def set_artwork_url
        image_links = @track&.dig('album_resource', 'attributes', 'imageLinks') || []
        largest = image_links.max_by { |link| link.dig('meta', 'width').to_i }
        largest&.dig('href')
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
