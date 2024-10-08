module Spotify
  class Base
    attr_reader :args

    def initialize(args)
      @args = args
    end

    def make_request(url)
      attempts ||= 1
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Get.new(url)
      request['Authorization'] = "Bearer #{token}"
      request['Content-Type'] = 'application/json'

      Rails.cache.fetch(url.to_s, expires_in: 12.hours) do
        JSON(https.request(request).body)
      end
    rescue StandardError => e
      if attempts < 3
        attempts += 1
        retry
      else
        ExceptionNotifier.notify_new_relic(e)
        nil
      end
    end

    def make_request_with_match(url)
      tracks = make_request(url)
      items = Spotify::Track::Filter::ResultsDigger.new(tracks:).execute

      if tracks&.dig('tracks', 'items').present?
        tracks['tracks']['items'] = add_match(items)
        tracks
      elsif tracks&.dig('album', 'album_type').present?
        tracks
      end
    end

    private

    def token
      Spotify::Token.new.get_token
    end

    def string_distance(item_string)
      (JaroWinkler.similarity(item_string, "#{args[:artists]} #{args[:title]}") * 100).to_i
    end

    def add_match(items)
      items.map do |item|
        next if item.blank?

        item_artist_names = item.dig('album', 'artists').map { |artist| artist['name'] }.join(' ')
        item_full_name = "#{item_artist_names} #{item['name']}"
        distance = string_distance(item_full_name)
        item['title_distance'] = distance
        item['match'] = item['popularity'] + (distance * 2)
        item
      end
    end
  end
end
