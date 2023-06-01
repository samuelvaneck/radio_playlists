module Spotify
  module Track
    class Filter < Base
      attr_reader :search_results, :artists
      def initialize(search_results, search_artists)
        @search_results = search_results
        @artists = search_artists
      end

      def execute
        tracks = if @search_results.dig('tracks', 'items').present?
                   @search_results['tracks']['items']
                 elsif @search_results.dig('album', 'album_type').present?
                   @search_results
                 end
        return if tracks.blank?

        Array.wrap(tracks)&.reject do |item|
          item_artist_names = item['album']['artists'].map { |artist| artist['name'] }
          different_artists = item_artist_names.join(', ') != @artists
          item['album']['album_type'] == 'compilation' && different_artists
        end
      end
    end
  end
end
