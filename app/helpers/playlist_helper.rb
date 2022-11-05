# frozen_string_literal: true

module PlaylistHelper
  def radio_veronica_top_song_count(top_song, time)
    radio_station_id = RadioStation.find_by(name: 'Radio Veronica').id
    fetch_counts_per_radio_station(top_song, time, radio_station_id)
  end

  def radio_2_top_song_count(top_song, time)
    radio_station_id = RadioStation.find_by(name: 'Radio 2').id
    fetch_counts_per_radio_station(top_song, time, radio_station_id)
  end

  def radio_3fm_top_song_count(top_song, time)
    radio_station_id = RadioStation.find_by(name: 'Radio 3FM').id
    fetch_counts_per_radio_station(top_song, time, radio_station_id)
  end

  def sublime_fm_top_song_count(top_song, time)
    radio_station_id = RadioStation.find_by(name: 'Sublime FM').id
    fetch_counts_per_radio_station(top_song, time, radio_station_id)
  end

  def sky_radio_top_song_count(top_song, time)
    radio_station_id = RadioStation.find_by(name: 'Sky Radio').id
    fetch_counts_per_radio_station(top_song, time, radio_station_id)
  end

  def q_music_top_song_count(top_song, time)
    radio_station_id = RadioStation.find_by(name: 'Qmusic').id
    fetch_counts_per_radio_station(top_song, time, radio_station_id)
  end

  def grootnieuws_radio_top_song_count(top_song, time)
    radio_station_id = RadioStation.find_by(name: 'Groot Nieuws Radio').id
    fetch_counts_per_radio_station(top_song, time, radio_station_id)
  end

  def radio_538_top_song_count(top_song, time)
    radio_station_id = RadioStation.find_by(name: 'Radio 538').id
    fetch_counts_per_radio_station(top_song, time, radio_station_id)
  end

  def fetch_counts_per_radio_station(top_song, time, radio_station_id)
    return Playlist.where('song_id = ? AND radio_station_id = ?', top_song, radio_station_id).count if time.blank?

    case time
    when 'day'
      Playlist.where('song_id = ? AND radio_station_id = ? AND created_at > ?', top_song, radio_station_id, 1.day.ago).count
    when 'week'
      Playlist.where('song_id = ? AND radio_station_id = ? AND created_at > ?', top_song, radio_station_id, 1.week.ago).count
    when 'month'
      Playlist.where('song_id = ? AND radio_station_id = ? AND created_at > ?', top_song, radio_station_id, 1.month.ago).count
    when 'year'
      Playlist.where('song_id = ? AND radio_station_id = ? AND created_at > ?', top_song, radio_station_id, 1.year.ago).count
    when 'total'
      Playlist.where('song_id = ? AND radio_station_id = ?', top_song, radio_station_id).count
    end
  end

  def radio_veronica_top_artist_count(top_artist, time)
    radio_station_id = RadioStation.find_by(name: 'Radio Veronica').id
    fetch_counts_artist_per_radio_station(top_artist, time, radio_station_id)
  end

  def radio_2_top_artist_count(top_artist, time)
    radio_station_id = RadioStation.find_by(name: 'Radio 2').id
    fetch_counts_artist_per_radio_station(top_artist, time, radio_station_id)
  end

  def radio_3fm_top_artist_count(top_artist, time)
    radio_station_id = RadioStation.find_by(name: 'Radio 3FM').id
    fetch_counts_artist_per_radio_station(top_artist, time, radio_station_id)
  end

  def sublime_fm_top_artist_count(top_artist, time)
    radio_station_id = RadioStation.find_by(name: 'Sublime FM').id
    fetch_counts_artist_per_radio_station(top_artist, time, radio_station_id)
  end

  def sky_radio_top_artist_count(top_artist, time)
    radio_station_id = RadioStation.find_by(name: 'Sky Radio').id
    fetch_counts_artist_per_radio_station(top_artist, time, radio_station_id)
  end

  def q_music_top_artist_count(top_artist, time)
    radio_station_id = RadioStation.find_by(name: 'Qmusic').id
    fetch_counts_artist_per_radio_station(top_artist, time, radio_station_id)
  end

  def grootnieuws_radio_top_artist_count(top_artist, time)
    radio_station_id = RadioStation.find_by(name: 'Groot Nieuws Radio').id
    fetch_counts_artist_per_radio_station(top_artist, time, radio_station_id)
  end

  def radio_538_top_artist_count(top_artist, time)
    radio_station_id = RadioStation.find_by(name: 'Radio 538').id
    fetch_counts_artist_per_radio_station(top_artist, time, radio_station_id)
  end

  def fetch_counts_artist_per_radio_station(top_artist, time, radio_station_id)
    return Playlist.where('artist_id = ? AND radio_station_id = ?', top_artist, radio_station_id).count if time.blank?

    case time
    when 'day'
      Playlist.where('artist_id = ? AND radio_station_id = ? AND created_at > ?', top_artist, radio_station_id, 1.day.ago).count
    when 'week'
      Playlist.where('artist_id = ? AND radio_station_id = ? AND created_at > ?', top_artist, radio_station_id, 1.week.ago).count
    when 'month'
      Playlist.where('artist_id = ? AND radio_station_id = ? AND created_at > ?', top_artist, radio_station_id, 1.month.ago).count
    when 'year'
      Playlist.where('artist_id = ? AND radio_station_id = ? AND created_at > ?', top_artist, radio_station_id, 1.year.ago).count
    when 'total'
      Playlist.where('artist_id = ? AND radio_station_id = ?', top_artist, radio_station_id).count
    end
  end
end
