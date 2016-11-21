module GeneralplaylistHelper

  def radiostation_name(radiostation_id)
    name = Radiostation.find(radiostation_id).name
    return name
  end

  def artist_name(artist_id)
    name = Artist.find(artist_id).name
    return name
  end

  def song_title(song_id)
    title = Song.find(song_id).title
    return title
  end

  def date(created_at)
    return created_at.strftime("%e-%b-%Y")
  end

end
