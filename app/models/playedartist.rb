class Playedartist < ActiveRecord::Base
  belongs_to :artist
  belongs_to :generalplaylist
end
