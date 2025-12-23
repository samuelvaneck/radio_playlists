# frozen_string_literal: true

module Wikipedia
  class ArtistFinder < Base
    ALLOWED_TAGS = %w[p b i a br em strong].freeze

    def get_info(artist_name)
      encoded_name = ERB::Util.url_encode(artist_name)
      response = make_request("/page/summary/#{encoded_name}")
      return nil if response.nil? || response['type'] != 'standard'

      {
        'summary' => sanitize_html(response['extract_html']),
        'description' => response['description'],
        'url' => response.dig('content_urls', 'desktop', 'page')
      }
    end

    private

    def sanitize_html(html)
      return nil if html.nil?

      ActionController::Base.helpers.sanitize(html, tags: ALLOWED_TAGS)
    end
  end
end
