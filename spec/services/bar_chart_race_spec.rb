# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BarChartRace do
  describe '.for' do
    let(:radio_station) { create(:radio_station) }
    let(:params) { { period: 'week' } }

    it 'returns CumulativeFrames by default' do
      expect(described_class.for(type: nil, radio_station:, params:)).to be_a(BarChartRace::CumulativeFrames)
    end

    it 'returns CumulativeFrames for cumulative_frames type' do
      expect(described_class.for(type: 'cumulative_frames', radio_station:, params:)).to be_a(BarChartRace::CumulativeFrames)
    end

    it 'returns DayChart for day_chart type' do
      expect(described_class.for(type: 'day_chart', radio_station:, params:)).to be_a(BarChartRace::DayChart)
    end
  end
end
