class AddCachedChartPositionsToArtists < ActiveRecord::Migration[7.2]
  def change
    add_column :artists, :cached_chart_positions, :jsonb, default: []
  end
end
