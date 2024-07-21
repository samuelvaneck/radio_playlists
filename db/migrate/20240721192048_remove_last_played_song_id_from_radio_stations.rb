class RemoveLastPlayedSongIdFromRadioStations < ActiveRecord::Migration[7.1]
  def change
    remove_column :radio_stations, :last_played_song_id
  end
end
