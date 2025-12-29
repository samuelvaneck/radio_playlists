# frozen_string_literal: true

class SongImporter::Matcher < SongImporter
  attr_reader :radio_station, :song
  def initialize(radio_station:, song:)
    @radio_station = radio_station
    @song = song
  end

  def matches_any_played_last_hour?
    # Use any? with early exit for better performance
    @radio_station.songs_played_last_hour.any? do |played_song|
      song_match(played_song) > 80
    end
  end

  def song_matches
    # Use map directly instead of find_each.map (find_each is for batch processing large datasets)
    @radio_station.songs_played_last_hour.map do |played_song|
      song_match(played_song)
    end
  end

  def song_match(played_song)
    # Artists are already eager loaded from songs_played_last_hour
    played_song_search_text = "#{played_song.artists.map(&:name).join(' ')} #{played_song.title}".downcase
    (JaroWinkler.similarity(played_song_search_text, song_search_text) * 100).to_i
  end

  private

  def song_search_text
    @song_search_text ||= "#{@song.artists.map(&:name).join(' ')} #{@song.title}".downcase
  end
end
