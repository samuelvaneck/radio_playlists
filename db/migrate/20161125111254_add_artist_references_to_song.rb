class AddArtistReferencesToSong < ActiveRecord::Migration[5.1]
  def change
    add_reference :songs, :artist, index: true, foreign_key: true
  end
end
