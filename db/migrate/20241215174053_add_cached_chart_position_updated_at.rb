class AddCachedChartPositionUpdatedAt < ActiveRecord::Migration[7.2]
  def change
    add_column :songs, :cached_chart_positions_updated_at, :datetime
    add_column :artists, :cached_chart_positions_updated_at, :datetime
  end
end
