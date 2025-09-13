# frozen_string_literal: true

module Lastfm
  class TrackFinder < Base
    def search(artist_name, track_name, limit: 10)
      return nil unless artist_name.present? && track_name.present?

      params = {
        method: 'track.search',
        artist: artist_name,
        track: track_name,
        limit: limit
      }

      response = make_request(params)
      return nil unless response

      parse_search_results(response)
    rescue StandardError => e
      Rails.logger.error "Last.fm track search error: #{e.message}"
      nil
    end

    def get_info(artist_name, track_name)
      return nil unless artist_name.present? && track_name.present?

      params = {
        method: 'track.getInfo',
        artist: artist_name,
        track: track_name
      }

      response = make_request(params)
      return nil unless response

      parse_track_info(response)
    rescue StandardError => e
      Rails.logger.error "Last.fm track info error: #{e.message}"
      nil
    end

    def get_similar(artist_name, track_name, limit: 10)
      return nil unless artist_name.present? && track_name.present?

      params = {
        method: 'track.getSimilar',
        artist: artist_name,
        track: track_name,
        limit: limit
      }

      response = make_request(params)
      return nil unless response

      parse_similar_tracks(response)
    rescue StandardError => e
      Rails.logger.error "Last.fm similar tracks error: #{e.message}"
      nil
    end

    def get_top_tags(artist_name, track_name)
      return nil unless artist_name.present? && track_name.present?

      params = {
        method: 'track.getTopTags',
        artist: artist_name,
        track: track_name
      }

      response = make_request(params)
      return nil unless response

      parse_top_tags(response)
    rescue StandardError => e
      Rails.logger.error "Last.fm track tags error: #{e.message}"
      nil
    end

    private

    def parse_search_results(response)
      return nil unless response['results'] && response['results']['trackmatches']

      tracks = response['results']['trackmatches']['track']
      tracks = [tracks] unless tracks.is_a?(Array)

      tracks.map do |track|
        {
          name: track['name'],
          artist: track['artist'],
          url: track['url'],
          listeners: track['listeners']&.to_i,
          mbid: track['mbid'].presence,
          image: extract_image(track['image'])
        }
      end
    end

    def parse_track_info(response)
      return nil unless response['track']

      track = response['track']
      {
        name: track['name'],
        artist: extract_artist_info(track['artist']),
        mbid: track['mbid'].presence,
        url: track['url'],
        duration: track['duration']&.to_i,
        listeners: track['listeners']&.to_i,
        playcount: track['playcount']&.to_i,
        tags: extract_tags(track['toptags']),
        album: extract_album_info(track['album']),
        wiki: extract_wiki(track['wiki'])
      }
    end

    def parse_similar_tracks(response)
      return [] unless response['similartracks'] && response['similartracks']['track']

      tracks = response['similartracks']['track']
      tracks = [tracks] unless tracks.is_a?(Array)

      tracks.map do |track|
        {
          name: track['name'],
          artist: extract_artist_info(track['artist']),
          mbid: track['mbid'].presence,
          url: track['url'],
          match: track['match']&.to_f,
          duration: track['duration']&.to_i,
          playcount: track['playcount']&.to_i
        }
      end
    end

    def parse_top_tags(response)
      return [] unless response['toptags'] && response['toptags']['tag']

      tags = response['toptags']['tag']
      tags = [tags] unless tags.is_a?(Array)

      tags.map do |tag|
        {
          name: tag['name'],
          count: tag['count']&.to_i,
          url: tag['url']
        }
      end
    end

    def extract_artist_info(artist)
      return artist if artist.is_a?(String)
      return nil unless artist.is_a?(Hash)

      {
        name: artist['name'],
        mbid: artist['mbid'].presence,
        url: artist['url']
      }
    end

    def extract_album_info(album)
      return nil unless album.is_a?(Hash)

      {
        title: album['title'],
        artist: album['artist'],
        mbid: album['mbid'].presence,
        url: album['url'],
        image: extract_image(album['image'])
      }
    end

    def extract_tags(toptags)
      return [] unless toptags && toptags['tag']

      tags = toptags['tag']
      tags = [tags] unless tags.is_a?(Array)

      tags.map do |tag|
        tag.is_a?(Hash) ? tag['name'] : tag
      end
    end

    def extract_wiki(wiki)
      return nil unless wiki.is_a?(Hash)

      {
        published: wiki['published'],
        summary: wiki['summary'],
        content: wiki['content']
      }
    end
  end
end