# frozen_string_literal: true

# == Schema Information
#
# Table name: artists
#
#  id                  :bigint           not null, primary key
#  name                :string
#  image               :string
#  genre               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  spotify_artist_url  :string
#  spotify_artwork_url :string
#  id_on_spotify       :string
#
class ArtistSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :name, :spotify_artist_url, :spotify_artwork_url

  attribute :counter do |object|
    object.counter if object.respond_to?(:counter)
  end

  has_many :songs
end
