# frozen_string_literal: true

module Llm
  class ProgramDetector < Base
    attr_reader :raw_response

    def initialize(artist_name:, title:, radio_station_name:)
      super()
      @artist_name = artist_name
      @title = title
      @radio_station_name = radio_station_name
      @raw_response = {}
    end

    def program?
      response = chat(system_prompt: system_prompt, user_message: user_message, max_tokens: 10)
      @raw_response = { request: user_message.strip, response: response }
      return false if response.blank?

      response.strip.downcase.start_with?('yes')
    end

    private

    def system_prompt
      <<~PROMPT
        You are a Dutch radio expert. Determine if the given artist/title combination is a radio
        program, show, or segment rather than an actual music track.

        Radio programs/shows typically have:
        - An artist name that matches or contains the radio station name
        - Dutch show names like "Housuh In De Pauzuh", "De Ochtendshow", "De Top 40", "Muziek Non-stop"
        - News blocks, segment names, jingle descriptions, or ad breaks
        - Generic labels like "Non-stop", "Muziek", "Live"

        An actual song typically has a distinct artist name unrelated to the station and a
        recognizable song title.

        Answer ONLY "yes" if it is a radio program/show/segment, or "no" if it is an actual song.
      PROMPT
    end

    def user_message
      "Radio station: #{@radio_station_name}\nArtist: #{@artist_name}\nTitle: #{@title}"
    end
  end
end
