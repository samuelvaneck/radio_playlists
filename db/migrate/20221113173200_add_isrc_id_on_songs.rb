class AddIsrcIdOnSongs < ActiveRecord::Migration[7.0]
  def change
    add_column :songs, :isrc_id, :string
  end
end
