class SongUpdateChartPositionsJob < ApplicationJob
  queue_as :default

  def perform(song_id)
    Song.find(song_id)&.update_chart_positions
  end
end
