class Generalplaylist < ActiveRecord::Base
  has_many :playedartists
  has_many :artists, through: :playedartists

  has_many :playedsongs
  has_many :songs, through: :playedsongs

  has_many :playedradiostations
  has_many :radiostations, through: :playedradiostations
end
