module GeneralplaylistHelper

  def random_album_image(top_artist)
    image = nil
    if top_artist.songs.map {|song| song.artwork_url}.any?
      while image == nil do
        image = top_artist.songs.map { |song| song.artwork_url }.sample
      end
    end
    return image
  end

  def top_song_count(top_song, time, name)
    radiostation_id = Radiostation.find_by(name: name).id
    fetch_counts_per_radio_station(top_song, time, radiostation_id)
  end

  def top_artist_count(top_artist, time, name)
    radiostation_id = Radiostation.find_by(name: name).id
    fetch_counts_artist_per_radio_station(top_artist, time, radiostation_id)
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
