class Generalplaylist < ActiveRecord::Base
  has_and_belongs_to_many :radiostations
  has_and_belongs_to_many :artists
  has_and_belongs_to_many :songs
end
