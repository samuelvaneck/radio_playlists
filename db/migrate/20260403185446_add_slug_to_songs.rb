class AddSlugToSongs < ActiveRecord::Migration[8.1]
  def change
    add_column :songs, :slug, :string
    add_index :songs, :slug, unique: true
  end
end
