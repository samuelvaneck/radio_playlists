module Spotify
  module Track
    module Filter
      class AlbumTracks
        attr_reader :tracks, :artists

        def initialize(args)
          @tracks = args[:tracks]
          @artists = args[:artists]
        end

        def most_popular
          MostPopular.new(tracks: same_artists_filter).execute
        end

        def most_popular_track
          @tracks = filter
          MostPopular.new(tracks: @tracks).execute
        end

        def best_matching
          best_matching_track&.dig('match')
        end

        def best_matching_track
          @tracks = filter
          BestMatch.new(tracks: @tracks).execute
        end

        private

        def filter_for_same_artists
          SameArtistsFilter.new(tracks: filter, artists: @artists).execute
        end

        def filter
          return [] if @tracks.blank?

          dig_for_usable_tracks.select do |track|
            track.dig('album', 'album_type') == 'album'
          end
        end

        def track_artist_names(track)
          album_artists = track['album']['artists'].map { |artist| artist['name'] }
          artists = if album_artists.include?('Various Artists')
                      track['artists']
                    else
                      track['album']['artists']
                    end
          artists.map { |artist| artist['name'] }.join(', ')
        end

        def same_artists(track)
          track_artist_names(track) == @artists
        end

        def dig_for_usable_tracks
          ResultsDigger.new(tracks: @tracks).execute
        end
      end
    end
  end
end
