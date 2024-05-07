# frozen_string_literal: true

# == Schema Information
#
# Table name: songs
#
#  id                  :bigint           not null, primary key
#  title               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  fullname            :text
#  spotify_song_url    :string
#  spotify_artwork_url :string
#  id_on_spotify       :string
#  isrc                :string
#
class SongSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :title,
             :fullname,
             :spotify_song_url,
             :spotify_artwork_url,
             :counter,
             :artists

  def artists
    object.artists.map do |artist|
      ArtistSerializer.new(artist)
    end
  end
end
