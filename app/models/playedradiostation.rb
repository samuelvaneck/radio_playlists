class Playedradiostation < ActiveRecord::Base
  has_many :generalplaylist
  has_many :radiostation
end
