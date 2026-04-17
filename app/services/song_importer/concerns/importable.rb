# frozen_string_literal: true

module SongImporter::Concerns
  module Importable
    extend ActiveSupport::Concern

    def may_import_song?
      not_last_added_song && !any_song_matches?
    end

    def broadcast_error_message
      Broadcaster.last_song(title: @song.title, artists_names:, radio_station_name: @radio_station.name)
    end

    private

    def any_song_matches?
      SongImporter::Matcher.new(radio_station: @radio_station, song: @song).matches_any_played_last_hour?
    end

    def artists_names
      Array.wrap(@artists).map(&:name).join(', ')
    end
  end
end
