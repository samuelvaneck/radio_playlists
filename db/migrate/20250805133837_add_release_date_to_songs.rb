class AddReleaseDateToSongs < ActiveRecord::Migration[8.0]
  def change
    add_column :songs, :release_date, :date
    add_index :songs, :release_date
  end
end
