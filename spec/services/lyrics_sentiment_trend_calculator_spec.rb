# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LyricsSentimentTrendCalculator do
  let(:radio_station) { create(:radio_station) }
  let(:positive_song) { create(:song) }
  let(:negative_song) { create(:song) }
  let(:unanalyzed_song) { create(:song) }

  before do
    create(:lyric, song: positive_song, sentiment: 0.6)
    create(:lyric, song: negative_song, sentiment: -0.4)
    # unanalyzed_song has no lyric — should be excluded from the average
  end

  describe '#calculate' do
    let(:calculator) { described_class.new(radio_station: radio_station, period: '7_days') }

    context 'when station has airplays in range with sentiment data' do
      before do
        create(:air_play, radio_station: radio_station, song: positive_song, broadcasted_at: 1.day.ago)
        create(:air_play, radio_station: radio_station, song: negative_song, broadcasted_at: 1.day.ago)
        create(:air_play, radio_station: radio_station, song: unanalyzed_song, broadcasted_at: 1.day.ago)
      end

      it 'returns one bucket with the averaged sentiment of songs that have lyrics', :aggregate_failures do
        result = calculator.calculate
        expect(result.size).to eq(1)
        expect(result.first[:average_sentiment]).to be_within(0.001).of(0.1)
        expect(result.first[:play_count]).to eq(2)
      end
    end

    context 'when station has airplays across multiple days' do
      before do
        create(:air_play, radio_station: radio_station, song: positive_song, broadcasted_at: 3.days.ago)
        create(:air_play, radio_station: radio_station, song: negative_song, broadcasted_at: 1.day.ago)
      end

      it 'returns separate buckets per day, sorted ascending', :aggregate_failures do
        result = calculator.calculate
        expect(result.size).to eq(2)
        expect(result.map { |r| r[:period_start] }).to eq(result.map { |r| r[:period_start] }.sort)
      end
    end

    context 'when station has no airplays in range' do
      it 'returns an empty array' do
        expect(calculator.calculate).to eq([])
      end
    end

    context 'when period is "all"' do
      let(:calculator) { described_class.new(radio_station: radio_station, period: 'all') }

      before do
        create(:air_play, radio_station: radio_station, song: positive_song, broadcasted_at: 2.years.ago)
        create(:air_play, radio_station: radio_station, song: negative_song, broadcasted_at: 1.day.ago)
      end

      it 'buckets by year' do
        years = calculator.calculate.map { |r| r[:period_start].year }
        expect(years.uniq.size).to eq(2)
      end
    end

    context 'when no period is provided' do
      let(:calculator) { described_class.new(radio_station: radio_station, period: nil) }

      before do
        create(:air_play, radio_station: radio_station, song: positive_song, broadcasted_at: 1.day.ago)
      end

      it 'defaults to 4 weeks and returns data' do
        expect(calculator.calculate).not_to be_empty
      end
    end
  end
end
