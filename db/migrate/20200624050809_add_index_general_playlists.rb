class AddIndexGeneralPlaylists < ActiveRecord::Migration[6.0]
  def up
    add_column :generalplaylists, :broadcast_timestamp, :datetime

    remove_column :generalplaylists, :time, :string
    add_index :generalplaylists, [:song_id, :radio_station_id, :broadcast_timestamp], unique: true, name: 'playlist_radio_song_time'
  end

  def down
    remove_index :generalplaylists, [:song_id, :radio_station_id, :broadcast_timestamp]
    add_column :generalplaylists, :time, :string

    Generalplaylist.find_in_batches do |group|
      group.each do |playlist|
        next if playlist.time.present?

        playlist.update(time: playlist.created_at.strftime('%H:%M'))
      end
    end

    remove_column :generalplaylists, :broadcast_timestamp, :datetime
  end
end
