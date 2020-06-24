class AddIndexGeneralPlaylists < ActiveRecord::Migration[6.0]
  def up
    add_column :generalplaylists, :broadcast_timestamp, :datetime

    Generalplaylist.all.each do |playlist|
      playlist.update(broadcast_timestamp: Time.parse(playlist.created_at.strftime('%F') + ' ' + playlist.time))
    end

    remove_column :generalplaylists, :time, :string
    add_index :generalplaylists, [:song_id, :radiostation_id, :broadcast_timestamp], unique: true, name: 'playlist_radio_song_time'
  end

  def down
    remove_index :generalplaylists, [:song_id, :radiostation_id, :broadcast_timestamp], unique: true, name: 'playlist_radio_song_time'
    add_column :generalplaylists, :time, :string

    Generalplaylist.all.each do |playlist|
      playlist.update(time: playlist.created_at.strftime('%H:%M'))
    end

    remove_column :generalplaylists, :broadcast_timestamp, :datetime
  end
end
