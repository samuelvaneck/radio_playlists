# frozen_string_literal: true

module Lastfm
  class SongEnricher
    def initialize
      @track_finder = Lastfm::TrackFinder.new
      @artist_finder = Lastfm::ArtistFinder.new
    end

    def enrich_song(song)
      return unless song.is_a?(Song)
      return if song.artists.blank?

      artist_name = song.artists.first.name
      track_info = @track_finder.get_info(artist_name, song.title)
      
      return unless track_info

      update_song_with_lastfm_data(song, track_info)
      enrich_artists(song.artists)
      
      song
    rescue StandardError => e
      Rails.logger.error "Last.fm song enrichment error for song #{song.id}: #{e.message}"
      nil
    end

    def enrich_artist(artist)
      return unless artist.is_a?(Artist)

      artist_info = @artist_finder.get_info(artist.name)
      return unless artist_info

      update_artist_with_lastfm_data(artist, artist_info)
      
      artist
    rescue StandardError => e
      Rails.logger.error "Last.fm artist enrichment error for artist #{artist.id}: #{e.message}"
      nil
    end

    def search_tracks(query, limit: 10)
      return [] if query.blank?

      # Try to split query into artist and track
      parts = query.split(' - ', 2)
      
      if parts.length == 2
        artist_name, track_name = parts
      else
        # If no clear separation, use the whole query for both
        artist_name = track_name = query
      end

      @track_finder.search(artist_name, track_name, limit: limit) || []
    rescue StandardError => e
      Rails.logger.error "Last.fm track search error: #{e.message}"
      []
    end

    def search_artists(query, limit: 10)
      return [] if query.blank?

      @artist_finder.search(query, limit: limit) || []
    rescue StandardError => e
      Rails.logger.error "Last.fm artist search error: #{e.message}"
      []
    end

    def get_similar_tracks(song, limit: 10)
      return [] unless song.is_a?(Song)
      return [] if song.artists.blank?

      artist_name = song.artists.first.name
      @track_finder.get_similar(artist_name, song.title, limit: limit) || []
    rescue StandardError => e
      Rails.logger.error "Last.fm similar tracks error: #{e.message}"
      []
    end

    def get_similar_artists(artist, limit: 10)
      return [] unless artist.is_a?(Artist)

      @artist_finder.get_similar(artist.name, limit: limit) || []
    rescue StandardError => e
      Rails.logger.error "Last.fm similar artists error: #{e.message}"
      []
    end

    private

    def update_song_with_lastfm_data(song, track_info)
      song.update(
        lastfm_url: track_info[:url],
        lastfm_listeners: track_info[:listeners],
        lastfm_playcount: track_info[:playcount],
        lastfm_tags: track_info[:tags],
        lastfm_mbid: track_info[:mbid]
      )
    end

    def update_artist_with_lastfm_data(artist, artist_info)
      bio_summary = artist_info[:bio][:summary] if artist_info[:bio]
      
      artist.update(
        lastfm_url: artist_info[:url],
        lastfm_listeners: artist_info[:listeners],
        lastfm_playcount: artist_info[:playcount],
        lastfm_tags: artist_info[:tags],
        lastfm_mbid: artist_info[:mbid],
        lastfm_bio: bio_summary
      )
    end

    def enrich_artists(artists)
      artists.each do |artist|
        enrich_artist(artist)
      end
    end
  end
end