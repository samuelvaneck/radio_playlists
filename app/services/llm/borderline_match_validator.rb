# frozen_string_literal: true

module Llm
  class BorderlineMatchValidator < Base
    BORDERLINE_TITLE_RANGE = (60...70)

    attr_reader :raw_response

    def initialize(scraped_title:, scraped_artist:, matched_title:, matched_artist:)
      super()
      @scraped_title = scraped_title
      @scraped_artist = scraped_artist
      @matched_title = matched_title
      @matched_artist = matched_artist
      @raw_response = {}
    end

    def same_song?
      response = chat(system_prompt: system_prompt, user_message: user_message, max_tokens: 64)
      @raw_response = { request: user_message.strip, response: response }
      return false if response.blank?

      response.strip.downcase.start_with?('yes')
    end

    private

    def system_prompt
      <<~PROMPT
        You are a music metadata expert. Given a scraped radio song and a potential Spotify match,
        determine if they are the SAME song. Variations like "(Radio Edit)", "(Remastered)", "(Live)",
        "(Acoustic Version)", or subtitle differences after " - " are still the same song.
        Different songs by the same artist are NOT the same song.

        Answer ONLY "yes" or "no".
      PROMPT
    end

    def user_message
      <<~MSG
        Scraped: "#{@scraped_artist} - #{@scraped_title}"
        Spotify: "#{@matched_artist} - #{@matched_title}"
      MSG
    end
  end
end
