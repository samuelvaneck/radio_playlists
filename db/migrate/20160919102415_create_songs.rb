class CreateSongs < ActiveRecord::Migration
  def change
    create_table :songs do |t|
      t.references :playlist, index: true, foreign_key: true
      t.string :artist
      t.string :title
      t.string :image
      t.string :fullname

      t.timestamps null: false
    end
  end
end
