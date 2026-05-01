class AddAkaNamesToArtists < ActiveRecord::Migration[8.1]
  def change
    change_table :artists, bulk: true do |t|
      t.string :aka_names, array: true, default: []
      t.string :id_on_musicbrainz
      t.datetime :aka_names_checked_at
    end

    add_index :artists, :aka_names, using: :gin
    add_index :artists, :id_on_musicbrainz, unique: true
  end
end
