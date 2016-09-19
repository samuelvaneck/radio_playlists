class Playlist < ActiveRecord::Base
  belongs_to :radiostation
  has_many :songs
end
