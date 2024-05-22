class RenameBroadcastTimeStampToBroadcastedAt < ActiveRecord::Migration[7.1]
  def change
    rename_column :playlists, :broadcast_timestamp, :broadcasted_at
  end
end
