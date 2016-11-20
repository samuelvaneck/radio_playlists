class Song < ActiveRecord::Base
  has_many :generalplaylists
end
