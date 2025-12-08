# frozen_string_literal: true

module Lastfm
  # rubocop:disable Metrics/ClassLength
  class ArtistFinder < Base
    def search(artist_name, limit: 10)
      return nil if artist_name.blank?

      params = {
        method: 'artist.search',
        artist: artist_name,
        limit: limit
      }

      response = make_request(params)
      return nil unless response

      parse_search_results(response)
    rescue StandardError => e
      Rails.logger.error "Last.fm artist search error: #{e.message}"
      nil
    end

    def get_info(artist_name)
      return nil if artist_name.blank?

      params = {
        method: 'artist.getInfo',
        artist: artist_name
      }

      response = make_request(params)
      return nil unless response

      parse_artist_info(response)
    rescue StandardError => e
      Rails.logger.error "Last.fm artist info error: #{e.message}"
      nil
    end

    def get_similar(artist_name, limit: 10)
      return nil if artist_name.blank?

      params = {
        method: 'artist.getSimilar',
        artist: artist_name,
        limit: limit
      }

      response = make_request(params)
      return nil unless response

      parse_similar_artists(response)
    rescue StandardError => e
      Rails.logger.error "Last.fm similar artists error: #{e.message}"
      nil
    end

    def get_top_tracks(artist_name, limit: 10)
      return nil if artist_name.blank?

      params = {
        method: 'artist.getTopTracks',
        artist: artist_name,
        limit: limit
      }

      response = make_request(params)
      return nil unless response

      parse_top_tracks(response)
    rescue StandardError => e
      Rails.logger.error "Last.fm top tracks error: #{e.message}"
      nil
    end

    def get_top_albums(artist_name, limit: 10)
      return nil if artist_name.blank?

      params = {
        method: 'artist.getTopAlbums',
        artist: artist_name,
        limit: limit
      }

      response = make_request(params)
      return nil unless response

      parse_top_albums(response)
    rescue StandardError => e
      Rails.logger.error "Last.fm top albums error: #{e.message}"
      nil
    end

    def get_top_tags(artist_name)
      return nil if artist_name.blank?

      params = {
        method: 'artist.getTopTags',
        artist: artist_name
      }

      response = make_request(params)
      return nil unless response

      parse_top_tags(response)
    rescue StandardError => e
      Rails.logger.error "Last.fm artist tags error: #{e.message}"
      nil
    end

    private

    def parse_search_results(response)
      return nil unless response['results'] && response['results']['artistmatches']

      artists = response['results']['artistmatches']['artist']
      artists = [artists] unless artists.is_a?(Array)

      artists.map do |artist|
        {
          name: artist['name'],
          mbid: artist['mbid'].presence,
          url: artist['url'],
          listeners: artist['listeners']&.to_i,
          image: extract_image(artist['image'])
        }
      end
    end

    def parse_artist_info(response)
      return nil unless response['artist']

      artist = response['artist']
      {
        name: artist['name'],
        mbid: artist['mbid'].presence,
        url: artist['url'],
        listeners: artist['stats']['listeners']&.to_i,
        playcount: artist['stats']['playcount']&.to_i,
        tags: extract_tags(artist['tags']),
        similar: extract_similar_artists(artist['similar']),
        bio: extract_bio(artist['bio']),
        image: extract_image(artist['image']),
        on_tour: artist['ontour'] == '1'
      }
    end

    def parse_similar_artists(response)
      return [] unless response['similarartists'] && response['similarartists']['artist']

      artists = response['similarartists']['artist']
      artists = [artists] unless artists.is_a?(Array)

      artists.map do |artist|
        {
          name: artist['name'],
          mbid: artist['mbid'].presence,
          url: artist['url'],
          match: artist['match']&.to_f,
          image: extract_image(artist['image'])
        }
      end
    end

    def parse_top_tracks(response)
      return [] unless response['toptracks'] && response['toptracks']['track']

      tracks = response['toptracks']['track']
      tracks = [tracks] unless tracks.is_a?(Array)

      tracks.map do |track|
        {
          name: track['name'],
          playcount: track['playcount']&.to_i,
          listeners: track['listeners']&.to_i,
          mbid: track['mbid'].presence,
          url: track['url'],
          rank: track['@attr'] ? track['@attr']['rank']&.to_i : nil,
          image: extract_image(track['image'])
        }
      end
    end

    def parse_top_albums(response)
      return [] unless response['topalbums'] && response['topalbums']['album']

      albums = response['topalbums']['album']
      albums = [albums] unless albums.is_a?(Array)

      albums.map do |album|
        {
          name: album['name'],
          playcount: album['playcount']&.to_i,
          mbid: album['mbid'].presence,
          url: album['url'],
          rank: album['@attr'] ? album['@attr']['rank']&.to_i : nil,
          image: extract_image(album['image'])
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

    def extract_tags(tags)
      return [] unless tags && tags['tag']

      tag_list = tags['tag']
      tag_list = [tag_list] unless tag_list.is_a?(Array)

      tag_list.map do |tag|
        tag.is_a?(Hash) ? tag['name'] : tag
      end
    end

    def extract_similar_artists(similar)
      return [] unless similar && similar['artist']

      artists = similar['artist']
      artists = [artists] unless artists.is_a?(Array)

      artists.take(5).map do |artist|
        {
          name: artist['name'],
          url: artist['url'],
          image: extract_image(artist['image'])
        }
      end
    end

    def extract_bio(bio)
      return nil unless bio.is_a?(Hash)

      {
        published: bio['published'],
        summary: bio['summary'],
        content: bio['content'],
        links: extract_links(bio['links'])
      }
    end

    def extract_links(links)
      return [] unless links && links['link']

      link_list = links['link']
      link_list = [link_list] unless link_list.is_a?(Array)

      link_list.map do |link|
        {
          rel: link['@attr'] ? link['@attr']['rel'] : nil,
          href: link['#text']
        }
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
