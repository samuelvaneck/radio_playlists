class AddNormalizedTitleToSongs < ActiveRecord::Migration[8.1]
  def change
    add_column :songs, :normalized_title, :string
    add_index :songs, :normalized_title
  end
end
