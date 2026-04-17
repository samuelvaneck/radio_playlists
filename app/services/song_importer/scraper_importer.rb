# frozen_string_literal: true

class SongImporter::ScraperImporter
  include SongImporter::Concerns::Importable

  attr_reader :radio_station, :artists, :song

  def initialize(radio_station:, artists:, song:)
    @radio_station = radio_station
    @artists = artists
    @song = song
  end

  private

  def not_last_added_song
    last_added_scraper_song != @song
  end

  def last_added_scraper_song
    @last_added_scraper_song ||= @radio_station.air_plays
                                   .scraper_imported
                                   .includes(:song)
                                   .order(created_at: :desc)
                                   .first&.song
  end
end
