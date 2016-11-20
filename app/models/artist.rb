class Artist < ActiveRecord::Base
  has_many :songs
  has_and_belongs_to_many :generalplaylists
end
