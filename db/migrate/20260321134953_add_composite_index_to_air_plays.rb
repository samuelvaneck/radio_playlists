class AddCompositeIndexToAirPlays < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :air_plays, [:radio_station_id, :status, :broadcasted_at],
              name: 'index_air_plays_on_station_status_broadcasted',
              algorithm: :concurrently
  end
end
