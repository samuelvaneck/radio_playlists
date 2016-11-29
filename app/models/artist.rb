class Artist < ActiveRecord::Base
  has_many :generalplaylists
  has_many :songs

  def self.destroy_all
    artists = Artists.all
    artists.each do |artist|
      artist.destroy
    end
  end

end
