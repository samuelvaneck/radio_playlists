# frozen_string_literal: true

class RemoveCachedChartPositionsFromSongsAndArtists < ActiveRecord::Migration[8.1]
  def change
    remove_column :songs, :cached_chart_positions, :jsonb, default: []
    remove_column :songs, :cached_chart_positions_updated_at, :datetime
    remove_column :artists, :cached_chart_positions, :jsonb, default: []
    remove_column :artists, :cached_chart_positions_updated_at, :datetime
  end
end
