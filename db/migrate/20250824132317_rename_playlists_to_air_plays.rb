class RenamePlaylistsToAirPlays < ActiveRecord::Migration[8.0]
  def change
    rename_index :playlists, 'index_playlists_on_radio_station_id', 'index_air_plays_on_radio_station_id'
    rename_index :playlists, 'playlist_radio_song_time', 'air_play_radio_song_time'
    rename_index :playlists, 'index_playlists_on_song_id', 'index_air_plays_on_song_id'
    rename_table :playlists, :air_plays
    rename_column :radio_stations, :last_added_playlist_ids, :last_added_air_play_ids
  end
end
