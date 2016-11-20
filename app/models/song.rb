class Song < ActiveRecord::Base
  belongs_to :artist
  has_many :playedsongs
  has_many :generalplaylists, through: :playedsongs
end
