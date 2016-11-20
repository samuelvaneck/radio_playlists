class CreateGeneralplaylists < ActiveRecord::Migration
  def change
    create_table :generalplaylists do |t|
      t.string :time
      t.references :song, index: true, foreign_key: true
      t.references :radiostation, index: true, foreign_key: true
      t.references :artist, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
