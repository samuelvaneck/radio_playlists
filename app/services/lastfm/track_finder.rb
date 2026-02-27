# frozen_string_literal: true

module Lastfm
  class TrackFinder < Base
    def get_info(artist_name:, track_name:)
      response = make_request(method: 'track.getInfo', artist: artist_name, track: track_name, autocorrect: 1)
      return nil if response.nil? || response['error'].present?

      response['track']
    end

    def get_top_tags(artist_name:, track_name:)
      response = make_request(method: 'track.gettoptags', artist: artist_name, track: track_name, autocorrect: 1)
      return nil if response.nil? || response['error'].present?

      response.dig('toptags', 'tag')
    end
  end
end
