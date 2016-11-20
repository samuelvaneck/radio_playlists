class Artist < ActiveRecord::Base
  has_many :playedartists
  has_many :generalplaylists, through: :playedartists
end
