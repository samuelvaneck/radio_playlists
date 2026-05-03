class AddTidalColumnsToSongs < ActiveRecord::Migration[8.1]
  def change
    change_table :songs, bulk: true do |t|
      t.string :id_on_tidal
      t.string :tidal_song_url
      t.string :tidal_artwork_url
      t.string :tidal_preview_url
    end

    add_index :songs, :id_on_tidal
  end
end
