class RenameRadiostationToRadioStation < ActiveRecord::Migration[7.0]
  def change
    rename_table :radiostations, :radio_stations
    rename_column :generalplaylists, :radiostation_id, :radio_station_id
  end
end
