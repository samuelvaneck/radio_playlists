class AddDurationMsToSongs < ActiveRecord::Migration[8.1]
  def change
    add_column :songs, :duration_ms, :integer
  end
end
