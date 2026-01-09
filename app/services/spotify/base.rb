module Spotify
  class Base
    include CircuitBreakable

    circuit_breaker_for :spotify

    ARTIST_SIMILARITY_THRESHOLD = 80
    TITLE_SIMILARITY_THRESHOLD = 70

    attr_reader :args

    def initialize(args)
      @args = args
    end

    def make_request(url)
      response = Rails.cache.fetch(url.to_s, expires_in: 12.hours) do
        with_circuit_breaker do
          with_exponential_backoff(max_attempts: 3, base_delay: 1) do
            api_response = connection.get(url) do |req|
              req.headers['Authorization'] = "Bearer #{token}"
              req.headers['Content-Type'] = 'application/json'
            end
            handle_rate_limit_response(api_response)
            api_response.body
          end
        end
      end
      response&.deep_dup
    rescue StandardError => e
      ExceptionNotifier.notify_new_relic(e)
      Rails.logger.error(e.message)
      nil
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
