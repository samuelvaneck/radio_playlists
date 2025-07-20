class AddIndexFirstBroadcastedAtOnRadioStationSongs < ActiveRecord::Migration[8.0]
  def change
    # Adding an index on the first_broadcasted_at column of the radio_station_songs table
    # This will improve query performance for filtering by first broadcasted date
    add_index :radio_station_songs, :first_broadcasted_at, if_not_exists: true, using: :btree
  end
end
