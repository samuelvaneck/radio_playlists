class AddScraperImportToPlaylist < ActiveRecord::Migration[7.0]
  def change
    add_column :playlists, :scraper_import, :boolean, default: false
  end
end
