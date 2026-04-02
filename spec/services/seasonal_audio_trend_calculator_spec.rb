# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SeasonalAudioTrendCalculator do
  describe '#calculate' do
    let(:radio_station) { create(:radio_station) }
    let(:start_time) { 6.months.ago }
    let(:end_time) { Time.current }
    let(:calculator) do
      described_class.new(radio_station_ids: [radio_station.id], start_time: start_time, end_time: end_time)
    end

    context 'when no data exists' do
      it 'returns nil' do
        expect(calculator.calculate).to be_nil
      end
    end

    context 'when airplays with music profiles exist' do
      let(:song) { create(:song) }
      let(:music_profile) do
        create(:music_profile, song: song, valence: 0.8, energy: 0.7, danceability: 0.65, tempo: 120.0)
      end

      before do
        music_profile
        create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 2.months.ago)
        create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 1.month.ago)
      end

      it 'returns series data with monthly aggregations', :aggregate_failures do
        result = calculator.calculate

        expect(result[:features]).to eq(%i[valence energy danceability tempo])
        expect(result[:series]).to be_an(Array)
        expect(result[:series].length).to be >= 2
        expect(result[:series].first).to have_key(:valence)
        expect(result[:series].first).to have_key(:energy)
        expect(result[:series].first).to have_key(:sample_size)
      end

      it 'returns summary with peak months', :aggregate_failures do
        result = calculator.calculate

        expect(result[:summary]).to be_a(Hash)
        expect(result[:summary]).to have_key(:peak_valence_month)
      end
    end

    context 'when filtering by multiple stations' do
      let(:station_a) { create(:radio_station) }
      let(:station_b) { create(:radio_station) }
      let(:song_a) { create(:song) }
      let(:song_b) { create(:song) }

      before do
        create(:music_profile, song: song_a, valence: 0.9, energy: 0.8, danceability: 0.7, tempo: 130.0)
        create(:music_profile, song: song_b, valence: 0.3, energy: 0.4, danceability: 0.3, tempo: 80.0)
        create(:air_play, song: song_a, radio_station: station_a, broadcasted_at: 1.month.ago)
        create(:air_play, song: song_b, radio_station: station_b, broadcasted_at: 1.month.ago)
      end

      it 'returns per-station data' do
        calc = described_class.new(radio_station_ids: [station_a.id, station_b.id], start_time: start_time,
                                   end_time: end_time)
        result = calc.calculate

        station_ids = result[:series].map { |row| row[:radio_station_id] }.uniq
        expect(station_ids).to contain_exactly(station_a.id, station_b.id)
      end
    end
  end
end
