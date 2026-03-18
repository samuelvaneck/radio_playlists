# frozen_string_literal: true

class AddAvgSongGapPerHourToRadioStations < ActiveRecord::Migration[8.1]
  def change
    add_column :radio_stations, :avg_song_gap_per_hour, :jsonb, default: {}
  end
end
