module Spotify
  class Base
    ARTIST_SIMILARITY_THRESHOLD = 80
    TITLE_SIMILARITY_THRESHOLD = 70

    attr_reader :args

    def initialize(args)
      @args = args
    end

    def make_request(url)
      attempts ||= 1

      response = Rails.cache.fetch(url.to_s, expires_in: 12.hours) do
        api_response = connection.get(url) do |req|
          req.headers['Authorization'] = "Bearer #{token}"
          req.headers['Content-Type'] = 'application/json'
        end
        handle_rate_limit(api_response)
        api_response.body
      end
      # Deep duplicate to prevent mutation of cached objects
      response.deep_dup
    rescue StandardError => e
      if attempts < 3
        attempts += 1
        retry
      else
        ExceptionNotifier.notify_new_relic(e)
        Rails.logger.error(e.message)
        nil
      end
    end

    def make_request_with_match(url)
      tracks = make_request(url)
      items = Spotify::TrackFinder::Filter::ResultsDigger.new(tracks:).execute

      if tracks&.dig('tracks', 'items').present?
        tracks['tracks']['items'] = add_match(items)
        tracks
      elsif tracks&.dig('album', 'album_type').present?
        tracks
      end
    end

    private

    def handle_rate_limit(response)
      return unless response.status == 429

      retry_after = response.headers['Retry-After']&.to_i || 30
      Rails.logger.warn("Spotify rate limit hit. Waiting #{retry_after} seconds.")
      sleep(retry_after)
      raise StandardError, 'Rate limited by Spotify API'
    end

    def connection
      Faraday.new(url: 'https://api.spotify.com') do |conn|
        conn.options.timeout = 10
        conn.options.open_timeout = 5
        conn.response :json
      end
    end

    def token
      Spotify::Token.new.token
    end

    def artist_distance(item_artist_names)
      (JaroWinkler.similarity(item_artist_names.downcase, args[:artists].to_s.downcase) * 100).to_i
    end

    def title_distance(item_title)
      (JaroWinkler.similarity(item_title.to_s.downcase, args[:title].to_s.downcase) * 100).to_i
    end

    def add_match(items)
      items.map do |item|
        next if item.blank?

        item_artist_names = item.dig('album', 'artists').map { |artist| artist['name'] }.join(' ')
        item_title = item['name']

        artist_dist = artist_distance(item_artist_names)
        title_dist = title_distance(item_title)

        item['artist_distance'] = artist_dist
        item['title_distance'] = title_dist
        # Use minimum of both distances to ensure both artist AND title match well
        # This prevents different songs by the same artist from getting high scores
        item['match'] = item['popularity'] + ([artist_dist, title_dist].min * 2)
        item
      end
    end
  end
end
