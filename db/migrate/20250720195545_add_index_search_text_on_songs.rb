class AddIndexSearchTextOnSongs < ActiveRecord::Migration[8.0]
  def change
    # Adding a full-text index on the search_text column of the songs table
    # This will improve search performance for text-based queries
    add_index :songs, :search_text, if_not_exists: true, using: :btree
  end
end
