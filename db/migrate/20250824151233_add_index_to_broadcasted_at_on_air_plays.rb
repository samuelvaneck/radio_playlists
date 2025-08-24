class AddIndexToBroadcastedAtOnAirPlays < ActiveRecord::Migration[8.0]
  def change
    add_index :air_plays, :broadcasted_at
  end
end
