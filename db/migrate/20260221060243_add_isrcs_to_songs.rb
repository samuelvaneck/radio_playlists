class AddIsrcsToSongs < ActiveRecord::Migration[8.1]
  def change
    add_column :songs, :isrcs, :string, array: true, default: []
  end
end
