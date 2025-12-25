# frozen_string_literal: true

module Wikipedia
  class SongFinder < Base
    ALLOWED_TAGS = %w[p b i a br em strong h2 h3 ul li dl dt dd].freeze

    def get_info(song_title, artist_name, include_general_info: true)
      return nil if song_title.blank?

      wikibase_item = find_wikibase_item(song_title, artist_name)
      return fetch_info_by_title(song_title, artist_name, include_general_info) if wikibase_item.blank?

      fetch_info_by_wikibase_item(wikibase_item, include_general_info)
    end

    def get_youtube_video_id(song_title, artist_name)
      return nil if song_title.blank?

      wikibase_item = find_wikibase_item(song_title, artist_name)
      return nil if wikibase_item.blank?

      WikidataFinder.new(language:).get_youtube_video_id(wikibase_item)
    end

    def get_youtube_video_id_by_spotify_id(spotify_id)
      return nil if spotify_id.blank?

      wikibase_item = WikidataFinder.new(language:).search_by_spotify_id(spotify_id)
      return nil if wikibase_item.blank?

      WikidataFinder.new(language:).get_youtube_video_id(wikibase_item)
    end

    def get_youtube_video_id_by_isrc(isrc)
      return nil if isrc.blank?

      wikibase_item = WikidataFinder.new(language:).search_by_isrc(isrc)
      return nil if wikibase_item.blank?

      WikidataFinder.new(language:).get_youtube_video_id(wikibase_item)
    end

    private

    def find_wikibase_item(song_title, artist_name)
      # Try fetching from Wikipedia page summary first
      search_query = build_search_query(song_title, artist_name)
      encoded_query = ERB::Util.url_encode(search_query)
      summary_response = make_rest_request("/page/summary/#{encoded_query}")

      return summary_response['wikibase_item'] if valid_song_response?(summary_response)

      # Try with just song title and "(song)" suffix
      encoded_title = ERB::Util.url_encode("#{song_title} (song)")
      summary_response = make_rest_request("/page/summary/#{encoded_title}")

      return summary_response['wikibase_item'] if valid_song_response?(summary_response)

      nil
    end

    def build_search_query(song_title, artist_name)
      return song_title if artist_name.blank?

      "#{song_title} (#{artist_name} song)"
    end

    def valid_song_response?(response)
      response.present? && response['type'] == 'standard' && response['wikibase_item'].present?
    end

    def fetch_info_by_wikibase_item(wikibase_item, include_general_info)
      # Get Wikipedia page title from Wikidata sitelinks
      entity_response = fetch_wikipedia_title_from_wikidata(wikibase_item)
      return nil if entity_response.blank?

      wikipedia_title = entity_response.dig('entities', wikibase_item, 'sitelinks', "#{language}wiki", 'title')
      return build_result_from_wikidata_only(wikibase_item, include_general_info) if wikipedia_title.blank?

      encoded_title = ERB::Util.url_encode(wikipedia_title)
      summary_response = make_rest_request("/page/summary/#{encoded_title}")
      return nil if summary_response.nil? || summary_response['type'] != 'standard'

      build_result(summary_response, wikibase_item, include_general_info)
    end

    def fetch_info_by_title(song_title, artist_name, include_general_info)
      search_query = build_search_query(song_title, artist_name)
      encoded_query = ERB::Util.url_encode(search_query)
      summary_response = make_rest_request("/page/summary/#{encoded_query}")

      return nil if summary_response.nil? || summary_response['type'] != 'standard'

      wikibase_item = summary_response['wikibase_item']
      build_result(summary_response, wikibase_item, include_general_info)
    end

    def build_result(summary_response, wikibase_item, include_general_info)
      title = summary_response['title']
      content = fetch_full_content(title)

      result = {
        'summary' => sanitize_html(summary_response['extract_html']),
        'content' => sanitize_html(content),
        'description' => summary_response['description'],
        'url' => summary_response.dig('content_urls', 'desktop', 'page'),
        'wikibase_item' => wikibase_item,
        'thumbnail' => summary_response['thumbnail'],
        'original_image' => summary_response['originalimage']
      }

      if include_general_info && wikibase_item.present?
        general_info = WikidataFinder.new(language:).get_song_info(wikibase_item)
        result['general_info'] = general_info if general_info.present?
      end

      result
    end

    def build_result_from_wikidata_only(wikibase_item, include_general_info)
      result = {
        'wikibase_item' => wikibase_item
      }

      if include_general_info
        general_info = WikidataFinder.new(language:).get_song_info(wikibase_item)
        result['general_info'] = general_info if general_info.present?
      end

      result
    end

    def fetch_wikipedia_title_from_wikidata(wikibase_item)
      Rails.cache.fetch("wikidata:sitelinks:#{language}:#{wikibase_item}", expires_in: 24.hours) do
        connection = Faraday.new(url: 'https://www.wikidata.org') { |conn| conn.response :json }
        response = connection.get('/w/api.php') do |req|
          req.params = {
            action: 'wbgetentities',
            ids: wikibase_item,
            format: 'json',
            props: 'sitelinks',
            sitefilter: "#{language}wiki"
          }
        end
        response.body
      end
    rescue StandardError => e
      ExceptionNotifier.notify_new_relic(e)
      Rails.logger.error("Wikidata sitelinks error: #{e.message}")
      nil
    end

    def fetch_full_content(title)
      response = make_mediawiki_request(titles: title, prop: 'extracts')
      return nil if response.nil?

      response.dig('query', 'pages')&.first&.dig('extract')
    end

    def sanitize_html(html)
      return nil if html.nil?

      ActionController::Base.helpers.sanitize(html, tags: ALLOWED_TAGS)
    end
  end
end
