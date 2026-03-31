class AddImportIntervalToRadioStations < ActiveRecord::Migration[8.1]
  def change
    add_column :radio_stations, :import_interval, :integer
  end
end
