class AddAcoustidSubmittedAtToSongs < ActiveRecord::Migration[8.1]
  def change
    add_column :songs, :acoustid_submitted_at, :datetime
    add_index :songs, :acoustid_submitted_at
  end
end
