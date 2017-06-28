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
end
