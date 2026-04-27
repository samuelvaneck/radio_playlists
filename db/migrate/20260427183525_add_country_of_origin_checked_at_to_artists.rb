class AddCountryOfOriginCheckedAtToArtists < ActiveRecord::Migration[8.1]
  def change
    add_column :artists, :country_of_origin_checked_at, :datetime
  end
end
