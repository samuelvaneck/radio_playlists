class AddUniqIndexOnArtistsSongs < ActiveRecord::Migration[7.0]
  def change
    Song.all.each do |song|
        song.artists = song.artists.uniq
    end

    add_index :artists_songs, [:artist_id, :song_id], unique: true
  end
end
