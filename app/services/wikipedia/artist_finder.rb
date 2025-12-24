# frozen_string_literal: true

module Wikipedia
  class ArtistFinder < Base
    ALLOWED_TAGS = %w[p b i a br em strong h2 h3 ul li dl dt dd].freeze

    def get_info(artist_name, include_general_info: true)
      encoded_name = ERB::Util.url_encode(artist_name)
      summary_response = make_rest_request("/page/summary/#{encoded_name}")
      return nil if summary_response.nil? || summary_response['type'] != 'standard'

      title = summary_response['title']
      content = fetch_full_content(title)
      wikibase_item = summary_response['wikibase_item']

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
        general_info = WikidataFinder.new(language: language).get_general_info(wikibase_item)
        result['general_info'] = general_info if general_info.present?
      end

      result
    end

    def get_official_website(artist_name)
      encoded_name = ERB::Util.url_encode(artist_name)
      summary_response = make_rest_request("/page/summary/#{encoded_name}")
      return nil if summary_response.nil? || summary_response['type'] != 'standard'

      wikibase_item = summary_response['wikibase_item']
      return nil if wikibase_item.blank?

      WikidataFinder.new(language: language).get_official_website(wikibase_item)
    end

    private

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
