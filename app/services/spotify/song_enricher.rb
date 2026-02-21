# frozen_string_literal: true

module Spotify
  class SongEnricher
    def initialize(song, force: false)
      @song = song
      @force = force
    end

    def enrich
      return if @song.blank?
      return if !@force && @song.spotify_song_url.present?

      result = find_on_spotify
      return if result.blank?

      updates = build_updates(result)
      # Use update_columns to skip callbacks (avoid triggering Deezer/iTunes enrichment)
      @song.update_columns(updates.compact) if updates.present? # rubocop:disable Rails/SkipsModelValidations

      update_artists(result) if @force
      @song
    end

    private

    def find_on_spotify
      if @song.id_on_spotify.present?
        # Use existing Spotify ID to fetch accurate data
        fetch_by_id
      else
        # Search by artist and title
        search_by_query
      end
    end

    def fetch_by_id
      response = Spotify::TrackFinder::FindById.new(id_on_spotify: @song.id_on_spotify).execute
      return nil if response.blank?

      # Wrap response in a struct-like object for consistent access
      OpenStruct.new(
        track: response,
        id: response['id'],
        spotify_song_url: response.dig('external_urls', 'spotify'),
        spotify_artwork_url: response.dig('album', 'images', 0, 'url'),
        spotify_preview_url: response['preview_url'],
        isrc: response.dig('external_ids', 'isrc'),
        duration_ms: response['duration_ms'],
        artists: response['artists']
      )
    end

    def search_by_query
      result = Spotify::TrackFinder::Result.new(
        artists: @song.artists.map(&:name).join(' '),
        title: @song.title
      )
      result.execute
      result
    end

    def build_updates(result)
      updates = {}
      updates[:id_on_spotify] = result.id if result.id.present?
      updates[:spotify_song_url] = result.spotify_song_url if result.spotify_song_url.present?
      updates[:spotify_artwork_url] = result.spotify_artwork_url if result.spotify_artwork_url.present?
      updates[:spotify_preview_url] = result.spotify_preview_url if result.spotify_preview_url.present?
      updates[:isrc] = result.isrc if result.isrc.present? && @song.isrc.blank?
      updates[:duration_ms] = result.duration_ms if result.duration_ms.present?
      updates
    end

    def update_artists(result)
      return if result.artists.blank?

      artists = result.artists.map do |artist_data|
        Artist.find_or_create_by(id_on_spotify: artist_data['id']) do |artist|
          artist.name = artist_data['name']
          artist.image = artist_data.dig('images', 0, 'url')
        end
      end

      @song.update_artists(artists) if artists.present?
    end
  end
end
