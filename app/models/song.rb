class Song < ActiveRecord::Base
  has_many :generalplaylists
  belongs_to :artist

  def self.destroy_all
    songs = Song.all
    songs.each do |song|
      song.destroy
    end
  end

end
