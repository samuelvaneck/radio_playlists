class Playedsong < ActiveRecord::Base
  has_many :songs
  has_many :generalplaylist
end
