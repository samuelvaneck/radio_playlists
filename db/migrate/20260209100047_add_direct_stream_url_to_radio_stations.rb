class AddDirectStreamUrlToRadioStations < ActiveRecord::Migration[8.1]
  def change
    add_column :radio_stations, :direct_stream_url, :string
  end
end
