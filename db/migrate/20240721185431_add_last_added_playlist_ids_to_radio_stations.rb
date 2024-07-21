class AddLastAddedPlaylistIdsToRadioStations < ActiveRecord::Migration[7.1]
  def change
    add_column :radio_stations, :last_added_playlist_ids, :jsonb
  end
end
