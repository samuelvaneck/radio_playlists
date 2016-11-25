module GeneralplaylistHelper

  def get_artist_name(artist_id)
    if artist_id != nil
      name = Artist.find(artist_id).name
      return name
    else
      return false
    end
  end

end
