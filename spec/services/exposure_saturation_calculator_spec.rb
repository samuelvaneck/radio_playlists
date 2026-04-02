# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExposureSaturationCalculator do
  describe '#calculate' do
    let(:radio_station) { create(:radio_station) }
    let(:start_time) { 1.week.ago }
    let(:end_time) { Time.current }
    let(:calculator) { described_class.new(radio_station: radio_station, start_time: start_time, end_time: end_time) }

    context 'when no airplays exist' do
      it 'returns nil' do
        expect(calculator.calculate).to be_nil
      end
    end

    context 'when one song is heavily overplayed' do
      let(:overplayed) { create(:song) }
      let(:normal_songs) { create_list(:song, 5) }

      before do
        50.times { create(:air_play, song: overplayed, radio_station: radio_station, broadcasted_at: 2.days.ago) }
        normal_songs.each do |song|
          3.times { create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 3.days.ago) }
        end
      end

      it 'flags the overplayed song', :aggregate_failures do
        result = calculator.calculate

        overplayed_entry = result[:songs].find { |s| s[:song_id] == overplayed.id }
        expect(overplayed_entry[:status]).to eq(:heavily_overexposed)
        expect(overplayed_entry[:saturation_index]).to be < 0.5
        expect(result[:overexposed_count]).to be >= 1
      end
    end

    context 'when all songs have similar play counts' do
      let(:songs) { create_list(:song, 5) }

      before do
        songs.each do |song|
          5.times { create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 2.days.ago) }
        end
      end

      it 'marks most songs as optimal', :aggregate_failures do
        result = calculator.calculate

        optimal_count = result[:songs].count { |s| s[:status] == :optimal }
        expect(optimal_count).to eq(5)
        expect(result[:overexposed_count]).to eq(0)
      end
    end

    context 'with response structure' do
      let(:song) { create(:song) }

      before do
        3.times { create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 2.days.ago) }
      end

      it 'returns expected shape', :aggregate_failures do
        result = calculator.calculate

        expect(result[:radio_station][:id]).to eq(radio_station.id)
        expect(result[:baseline]).to have_key(:median_plays)
        expect(result[:baseline]).to have_key(:mean_plays)
        expect(result[:baseline]).to have_key(:std_deviation)
        expect(result[:songs]).to be_an(Array)
        expect(result[:songs].first).to have_key(:exposure_ratio)
        expect(result[:songs].first).to have_key(:saturation_index)
      end
    end
  end
end
