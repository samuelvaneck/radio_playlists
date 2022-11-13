class AddIsrcOnSongs < ActiveRecord::Migration[7.0]
  def change
    add_column :songs, :isrc, :string
  end
end
