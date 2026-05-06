class AddCountryCodeToArtists < ActiveRecord::Migration[8.1]
  def change
    add_column :artists, :country_code, :string
  end
end
