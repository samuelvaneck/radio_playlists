class RemoveStreamUrlFromRadioStations < ActiveRecord::Migration[8.1]
  def change
    remove_column :radio_stations, :stream_url, :string
  end
end
