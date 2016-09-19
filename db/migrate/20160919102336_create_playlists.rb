class CreatePlaylists < ActiveRecord::Migration
  def change
    create_table :playlists do |t|
      t.references :radiostation, index: true, foreign_key: true
      t.integer :counter

      t.timestamps null: false
    end
  end
end
