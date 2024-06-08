class AddSlugAndCountryToRadioStations < ActiveRecord::Migration[7.1]
  def change
    add_column :radio_stations, :slug, :string
    add_column :radio_stations, :country_code, :string

    RadioStation.all.each do |radio_station|
      radio_station.update(slug: radio_station.name.parameterize, country_code: 'NLD')
    end
  end
end
