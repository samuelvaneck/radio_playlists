class AddImagesAndPreviewToSongs < ActiveRecord::Migration[5.1]
  def change
    add_column :songs, :song_preview, :text
    add_column :songs, :artwork_url, :text
  end
end
