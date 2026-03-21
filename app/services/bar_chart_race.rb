# frozen_string_literal: true

module BarChartRace
  TOP_N = 10

  def self.for(type:, radio_station:, params:)
    case type.to_s
    when 'day_chart'
      DayChart.new(radio_station:, params:)
    else
      CumulativeFrames.new(radio_station:, params:)
    end
  end
end
