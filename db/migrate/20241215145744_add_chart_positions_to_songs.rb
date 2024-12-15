class AddChartPositionsToSongs < ActiveRecord::Migration[7.2]
  def change
    add_column :songs, :cached_chart_positions, :jsonb, default: []
  end
end
