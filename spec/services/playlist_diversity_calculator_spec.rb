# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlaylistDiversityCalculator do
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

    context 'when one song dominates all plays' do
      let(:dominant_song) { create(:song) }
      let(:minor_songs) { create_list(:song, 4) }

      before do
        40.times { create(:air_play, song: dominant_song, radio_station: radio_station, broadcasted_at: 2.days.ago) }
        minor_songs.each do |song|
          create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 3.days.ago)
        end
      end

      it 'returns high gini and low normalized entropy', :aggregate_failures do
        result = calculator.calculate
        metrics = result[:metrics]

        expect(metrics[:gini_coefficient]).to be > 0.5
        expect(metrics[:normalized_entropy]).to be < 0.5
        expect(metrics[:hhi]).to be > 2500
      end
    end

    context 'when plays are uniformly distributed' do
      let(:songs) { create_list(:song, 5) }

      before do
        songs.each do |song|
          10.times { create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 2.days.ago) }
        end
      end

      it 'returns low gini and high normalized entropy', :aggregate_failures do
        result = calculator.calculate
        metrics = result[:metrics]

        expect(metrics[:gini_coefficient]).to be < 0.2
        expect(metrics[:normalized_entropy]).to be > 0.9
        expect(metrics[:hhi]).to be < 2500
        expect(metrics[:label]).to eq('highly diverse')
      end
    end

    context 'with response structure' do
      let(:song) { create(:song) }

      before do
        5.times { create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 2.days.ago) }
      end

      it 'returns the expected shape', :aggregate_failures do
        result = calculator.calculate

        expect(result[:radio_station][:id]).to eq(radio_station.id)
        expect(result[:period]).to have_key(:start_time)
        expect(result[:period]).to have_key(:end_time)
        expect(result[:sample][:unique_songs]).to eq(1)
        expect(result[:sample][:total_plays]).to eq(5)
        expect(result[:top_songs]).to be_an(Array)
      end
    end

    context 'when only draft airplays exist' do
      let(:song) { create(:song) }

      before do
        5.times { create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 2.days.ago, status: :draft) }
      end

      it 'returns nil' do
        expect(calculator.calculate).to be_nil
      end
    end
  end
end
