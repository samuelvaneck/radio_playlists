class CreatePlaylists < ActiveRecord::Migration
  def change
    create_table :playlists do |t|
      t.references :radiostation, index: true, foreign_key: true
      t.integer :counter
      t.string :artist
      t.string :title
      t.string :image
      t.string :fullname

      t.timestamps null: false
    end
  end
end
