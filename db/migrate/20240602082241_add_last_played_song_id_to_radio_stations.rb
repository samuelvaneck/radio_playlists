class AddLastPlayedSongIdToRadioStations < ActiveRecord::Migration[7.1]
  def change
    add_column :radio_stations, :last_played_song_id, :integer
  end
end
