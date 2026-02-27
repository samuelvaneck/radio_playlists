class AddCountryOfOriginToArtists < ActiveRecord::Migration[8.1]
  def change
    add_column :artists, :country_of_origin, :string, array: true, default: []
  end
end
