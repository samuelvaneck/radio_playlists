class Artist < ActiveRecord::Base
  has_many :generalplaylists
  has_many :songs
end
