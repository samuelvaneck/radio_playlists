class AddIndexNameOnArtists < ActiveRecord::Migration[8.0]
  def change
    # Adding a full-text index on the name column of the artists table
    # This will improve search performance for text-based queries
    add_index :artists, :name, if_not_exists: true, using: :btree
  end
end
