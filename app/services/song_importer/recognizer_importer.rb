# frozen_string_literal: true

class SongImporter::RecognizerImporter
  include SongImporter::Concerns::Importable

  attr_reader :radio_station, :artists, :song

  def initialize(radio_station:, artists:, song:)
    @radio_station = radio_station
    @artists = artists
    @song = song
  end

  private

  def not_last_added_song
    @radio_station.last_played_song != @song
  end
end
