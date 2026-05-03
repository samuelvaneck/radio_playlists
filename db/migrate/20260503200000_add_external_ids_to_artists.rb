class AddExternalIdsToArtists < ActiveRecord::Migration[8.1]
  def change
    change_table :artists, bulk: true do |t|
      t.string :id_on_tidal
      t.string :tidal_artist_url
      t.string :id_on_deezer
      t.string :deezer_artist_url
      t.string :deezer_artwork_url
      t.string :id_on_itunes
      t.string :itunes_artist_url
    end

    add_index :artists, :id_on_tidal
    add_index :artists, :id_on_deezer
    add_index :artists, :id_on_itunes
  end
end
