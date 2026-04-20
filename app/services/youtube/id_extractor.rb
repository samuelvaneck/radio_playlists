# frozen_string_literal: true

module Youtube
  # Normalizes a YouTube video ID from a share link or returns the input
  # unchanged when it already looks like a bare 11-character ID.
  #
  # Supports youtu.be share links, watch URLs, shorts URLs, and embeds.
  module IdExtractor
    VIDEO_ID_REGEX = /\A[A-Za-z0-9_-]{11}\z/
    URL_PATTERNS = [
      %r{youtu\.be/([A-Za-z0-9_-]{11})},
      /[?&]v=([A-Za-z0-9_-]{11})/,
      %r{/shorts/([A-Za-z0-9_-]{11})},
      %r{/embed/([A-Za-z0-9_-]{11})}
    ].freeze

    module_function

    def extract(input)
      value = input.to_s.strip
      return value if value.empty? || value.match?(VIDEO_ID_REGEX)

      URL_PATTERNS.each do |pattern|
        match = value.match(pattern)
        return match[1] if match
      end

      value
    end
  end
end
