class Radiostation < ActiveRecord::Base
  has_and_belongs_to_many :generalplaylists
end
