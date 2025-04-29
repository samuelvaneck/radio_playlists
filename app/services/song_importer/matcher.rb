# frozen_string_literal: true

class SongImporter::Matcher < SongImporter
  attr_reader :radio_station, :song
  def initialize(radio_station:, song:)
    @radio_station = radio_station
    @song = song
  end

  def matches_any_played_last_hour?
    song_matches.map { |n| n > 80 }.any?
  end

  def song_matches
    @radio_station.songs_played_last_hour.map do |played_song|
      song_match(played_song)
    end
  end

  def song_match(played_song)
    played_song_search_text = "#{played_song.artists.pluck(:name).join(' ')} #{played_song.title}".downcase
    song_search_text = "#{@song.artists.pluck(:name).join(' ')} #{@song.title}".downcase
    (JaroWinkler.similarity(played_song_search_text, song_search_text) * 100).to_i
  end
end
