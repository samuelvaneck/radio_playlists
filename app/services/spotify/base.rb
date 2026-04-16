module Spotify
  class Base
    ARTIST_SIMILARITY_THRESHOLD = 80
    TITLE_SIMILARITY_THRESHOLD = 70

    include CircuitBreakable

    circuit_breaker_for :spotify

    attr_reader :args

    def initialize(args)
      @args = args
    end

    def make_request(url)
      Rails.cache.fetch(url.to_s, expires_in: 12.hours) do
        with_circuit_breaker do
          with_exponential_backoff(max_attempts: 3, base_delay: 1) do
            api_response = connection.get(url) do |req|
              req.headers['Authorization'] = "Bearer #{token}"
              req.headers['Content-Type'] = 'application/json'
            end
            handle_rate_limit_response(api_response)
            api_response.body.is_a?(Hash) ? api_response.body : nil
          end
        end
      end
    rescue StandardError => e
      ExceptionNotifier.notify(e)
      Rails.logger.error(e.message)
      nil
    end

    def make_request_with_match(url)
      tracks = make_request(url)
      return nil if tracks.blank?

      items = Spotify::TrackFinder::Filter::ResultsDigger.new(tracks:).execute

      if tracks.dig('tracks', 'items').present?
        tracks.merge('tracks' => tracks['tracks'].merge('items' => add_match(items)))
      elsif tracks.dig('album', 'album_type').present?
        tracks
      end
    end

    private

    def connection
      @connection ||= Faraday.new(url: 'https://api.spotify.com') do |conn|
        conn.options.timeout = 10
        conn.options.open_timeout = 5
        conn.response :json
      end
    end

    def token
      Spotify::Token.new.token
    end

    def artist_distance(spotify_artist_names)
      scraped_names = split_artist_string(args[:artists].to_s).map { |name| without_leading_the(name) }.sort_by(&:downcase)
      spotify_names = spotify_artist_names.map { |name| without_leading_the(name) }.sort_by(&:downcase)

      (JaroWinkler.similarity(spotify_names.join(' ').downcase, scraped_names.join(' ').downcase) * 100).to_i
    end

    def split_artist_string(artist_string)
      regex = Regexp.new(Song::MULTIPLE_ARTIST_REGEX, Regexp::IGNORECASE)
      if artist_string.match?(regex)
        artist_string.split(regex).map(&:strip).reject(&:blank?)
      else
        [artist_string]
      end
    end

    def without_leading_the(name)
      name.sub(/\Athe\s+/i, '')
    end

    def title_distance(item_title)
      (JaroWinkler.similarity(item_title.to_s.downcase, args[:title].to_s.downcase) * 100).to_i
    end

    def add_match(items)
      items.filter_map do |item|
        next if item.blank?

        item_artist_names = item.dig('album', 'artists').map { |artist| artist['name'] }
        item_title = item['name']

        artist_dist = artist_distance(item_artist_names)
        title_dist = title_distance(item_title)

        # Use minimum of both distances to ensure both artist AND title match well
        # This prevents different songs by the same artist from getting high scores
        item.merge(
          'artist_distance' => artist_dist,
          'title_distance' => title_dist,
          'match' => item['popularity'] + ([artist_dist, title_dist].min * 2)
        )
      end
    end
  end
end
