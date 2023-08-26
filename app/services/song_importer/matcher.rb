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
    played_song_fullname = "#{played_song.artists.map(&:name).join(' ')} #{played_song.title}".downcase
    song_fullname = "#{@song.artists.map(&:name).join(' ')} #{@song.title}".downcase
    (JaroWinkler.distance(played_song_fullname, song_fullname) * 100).to_i
  end
end
