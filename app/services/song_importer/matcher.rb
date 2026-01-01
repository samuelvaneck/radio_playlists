# frozen_string_literal: true

class SongImporter::Matcher < SongImporter
  ARTIST_SIMILARITY_THRESHOLD = 80
  TITLE_SIMILARITY_THRESHOLD = 70

  attr_reader :radio_station, :song

  def initialize(radio_station:, song:)
    @radio_station = radio_station
    @song = song
  end

  def matches_any_played_last_hour?
    # Use any? with early exit for better performance
    # Check artist similarity first, then title similarity
    @radio_station.songs_played_last_hour.any? do |played_song|
      artist_match(played_song) >= ARTIST_SIMILARITY_THRESHOLD &&
        title_match(played_song) >= TITLE_SIMILARITY_THRESHOLD
    end
  end

  def song_matches
    # Use map directly instead of find_each.map (find_each is for batch processing large datasets)
    # Returns array of hashes with artist and title similarity scores
    @radio_station.songs_played_last_hour.map do |played_song|
      {
        artist_similarity: artist_match(played_song),
        title_similarity: title_match(played_song)
      }
    end
  end

  def song_match(played_song)
    # Returns the minimum of artist and title similarity
    # Both must be high for an overall high match score
    [artist_match(played_song), title_match(played_song)].min
  end

  def artist_match(played_song)
    played_artist_text = played_song.artists.map(&:name).join(' ').downcase
    (JaroWinkler.similarity(played_artist_text, artist_search_text) * 100).to_i
  end

  def title_match(played_song)
    played_title = played_song.title.to_s.downcase
    (JaroWinkler.similarity(played_title, title_search_text) * 100).to_i
  end

  private

  def artist_search_text
    @artist_search_text ||= @song.artists.map(&:name).join(' ').downcase
  end

  def title_search_text
    @title_search_text ||= @song.title.to_s.downcase
  end
end
