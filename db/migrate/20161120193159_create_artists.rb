class CreateArtists < ActiveRecord::Migration
  def change
    create_table :artists do |t|
      t.string :name
      t.string :image
      t.string :genre

      t.timestamps null: false
    end
  end
end
