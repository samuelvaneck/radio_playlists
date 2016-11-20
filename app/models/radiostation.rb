class Radiostation < ActiveRecord::Base
  has_many :playedradiostations
  has_many :generalplaylists, through: :playedradiostations
end
