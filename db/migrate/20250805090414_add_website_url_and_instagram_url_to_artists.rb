class AddWebsiteUrlAndInstagramUrlToArtists < ActiveRecord::Migration[8.0]
  def change
    add_column :artists, :website_url, :string
    add_column :artists, :instagram_url, :string
  end
end
