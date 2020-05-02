module GeneralplaylistHelper

  def random_album_image(top_artist)
    image = nil
    if top_artist.songs.map {|song| song.spotify_artwork_url}.any?
      while image == nil do
        image = top_artist.songs.map { |song| song.spotify_artwork_url }.sample
      end
    end
    image
  end

  def radio_veronica_top_song_count(top_song, time)
    radiostation_id = Radiostation.find_by(name: "Radio Veronica").id
    fetch_counts_per_radio_station(top_song, time, radiostation_id)
  end

  def radio_2_top_song_count(top_song, time)
    radiostation_id = Radiostation.find_by(name: "Radio 2").id
    fetch_counts_per_radio_station(top_song, time, radiostation_id)
  end

  def radio_3fm_top_song_count(top_song, time)
    radiostation_id = Radiostation.find_by(name: "Radio 3FM").id
    fetch_counts_per_radio_station(top_song, time, radiostation_id)
  end

  def sublime_fm_top_song_count(top_song, time)
    radiostation_id = Radiostation.find_by(name: "Sublime FM").id
    fetch_counts_per_radio_station(top_song, time, radiostation_id)
  end

  def sky_radio_top_song_count(top_song, time)
    radiostation_id = Radiostation.find_by(name: "Sky Radio").id
    fetch_counts_per_radio_station(top_song, time, radiostation_id)
  end

  def q_music_top_song_count(top_song, time)
    radiostation_id = Radiostation.find_by(name: "Qmusic").id
    fetch_counts_per_radio_station(top_song, time, radiostation_id)
  end

  def grootnieuws_radio_top_song_count(top_song, time)
    radiostation_id = Radiostation.find_by(name: "Groot Nieuws Radio").id
    fetch_counts_per_radio_station(top_song, time, radiostation_id)
  end

  def radio_538_top_song_count(top_song, time)
    radiostation_id = Radiostation.find_by(name: "Radio 538").id
    fetch_counts_per_radio_station(top_song, time, radiostation_id)
  end

  def fetch_counts_per_radio_station(top_song, time, radiostation_id)
    return Generalplaylist.where("song_id = ? AND radiostation_id = ?", top_song, radiostation_id).count if time.blank?
    case time
      when "day"
        return Generalplaylist.where("song_id = ? AND radiostation_id = ? AND created_at > ?", top_song, radiostation_id, 1.day.ago).count
      when "week"
        return Generalplaylist.where("song_id = ? AND radiostation_id = ? AND created_at > ?", top_song, radiostation_id, 1.week.ago).count
      when "month"
        return Generalplaylist.where("song_id = ? AND radiostation_id = ? AND created_at > ?", top_song, radiostation_id, 1.month.ago).count
      when "year"
        return Generalplaylist.where("song_id = ? AND radiostation_id = ? AND created_at > ?", top_song, radiostation_id, 1.year.ago).count
      when "total"
        return Generalplaylist.where("song_id = ? AND radiostation_id = ?", top_song, radiostation_id).count
    end
  end

  def radio_veronica_top_artist_count(top_artist, time)
    radiostation_id = Radiostation.find_by(name: "Radio Veronica").id
    fetch_counts_artist_per_radio_station(top_artist, time, radiostation_id)
  end

  def radio_2_top_artist_count(top_artist, time)
    radiostation_id = Radiostation.find_by(name: "Radio 2").id
    fetch_counts_artist_per_radio_station(top_artist, time, radiostation_id)
  end

  def radio_3fm_top_artist_count(top_artist, time)
    radiostation_id = Radiostation.find_by(name: "Radio 3FM").id
    fetch_counts_artist_per_radio_station(top_artist, time, radiostation_id)
  end

  def sublime_fm_top_artist_count(top_artist, time)
    radiostation_id = Radiostation.find_by(name: "Sublime FM").id
    fetch_counts_artist_per_radio_station(top_artist, time, radiostation_id)
  end

  def sky_radio_top_artist_count(top_artist, time)
    radiostation_id = Radiostation.find_by(name: "Sky Radio").id
    fetch_counts_artist_per_radio_station(top_artist, time, radiostation_id)
  end

  def q_music_top_artist_count(top_artist, time)
    radiostation_id = Radiostation.find_by(name: "Qmusic").id
    fetch_counts_artist_per_radio_station(top_artist, time, radiostation_id)
  end

  def grootnieuws_radio_top_artist_count(top_artist, time)
    radiostation_id = Radiostation.find_by(name: "Groot Nieuws Radio").id
    fetch_counts_artist_per_radio_station(top_artist, time, radiostation_id)
  end

  def radio_538_top_artist_count(top_artist, time)
    radiostation_id = Radiostation.find_by(name: "Radio 538").id
    fetch_counts_artist_per_radio_station(top_artist, time, radiostation_id)
  end

  def fetch_counts_artist_per_radio_station(top_artist, time, radiostation_id)
    return Generalplaylist.where("artist_id = ? AND radiostation_id = ?", top_artist, radiostation_id).count if time.blank?
    case time
      when "day"
        return Generalplaylist.where("artist_id = ? AND radiostation_id = ? AND created_at > ?", top_artist, radiostation_id, 1.day.ago).count
      when "week"
        return Generalplaylist.where("artist_id = ? AND radiostation_id = ? AND created_at > ?", top_artist, radiostation_id, 1.week.ago).count
      when "month"
        return Generalplaylist.where("artist_id = ? AND radiostation_id = ? AND created_at > ?", top_artist, radiostation_id, 1.month.ago).count
      when "year"
        return Generalplaylist.where("artist_id = ? AND radiostation_id = ? AND created_at > ?", top_artist, radiostation_id, 1.year.ago).count
      when "total"
        return Generalplaylist.where("artist_id = ? AND radiostation_id = ?", top_artist, radiostation_id).count
    end
  end
end
