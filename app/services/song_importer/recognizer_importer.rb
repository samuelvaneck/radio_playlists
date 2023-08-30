# frozen_string_literal: true

class SongImporter::RecognizerImporter < SongImporter
  def initialize(radio_station:, artists:, song:)
    @radio_station = radio_station
    @artists = artists
    @song = song
  end

  def may_import_song?
    not_last_added_song && !any_song_matches?
  end

  def broadcast_error_message
    Broadcaster.last_song(title: song.title, artists_names:, radio_station_name: @radio_station.name)
  end

  private

  def not_last_added_song
    @radio_station.last_played_song != @song
  end
end
