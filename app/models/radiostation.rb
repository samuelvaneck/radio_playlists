class Radiostation < ActiveRecord::Base
  has_many :generalplaylists
  has_many :songs, through: :generalplaylists
  has_many :artists, through: :generalplaylists
end
