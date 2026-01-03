# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RadioStationMusicProfileCalculator do
  describe 'constants' do
    it 'defines DAY_PARTS' do
      expect(described_class::DAY_PARTS).to eq(%w[night breakfast morning lunch afternoon dinner evening])
    end

    it 'defines DAY_PART_HOURS' do
      expect(described_class::DAY_PART_HOURS['afternoon']).to eq(13..15)
    end
  end

  describe '#calculate_for_day_part' do
    let(:radio_station) { create(:radio_station) }

    context 'when profiles exist for the day_part' do
      let(:danceable_song) { create(:song) }
      let(:speechy_song) { create(:song) }
      let(:calculator) do
        described_class.new(
          radio_station:,
          day_part: 'afternoon',
          start_time: Time.utc(2026, 1, 1),
          end_time: Time.utc(2026, 1, 3)
        )
      end

      before do
        create(:music_profile, song: danceable_song, danceability: 0.6, energy: 0.7, speechiness: 0.1,
                               acousticness: 0.3, instrumentalness: 0.1, liveness: 0.2, valence: 0.6, tempo: 120.0)
        create(:music_profile, song: speechy_song, danceability: 0.8, energy: 0.5, speechiness: 0.4,
                               acousticness: 0.5, instrumentalness: 0.6, liveness: 0.9, valence: 0.4, tempo: 130.0)

        # Create air plays with explicit UTC times that fall in afternoon (13-15) even after timezone conversion
        # Using 13 and 14 UTC which become 14 and 15 in CET (still afternoon)
        create(:air_play, song: danceable_song, radio_station:, broadcasted_at: Time.utc(2026, 1, 2, 13, 0, 0))
        create(:air_play, song: speechy_song, radio_station:, broadcasted_at: Time.utc(2026, 1, 2, 14, 0, 0))
      end

      it 'returns aggregated profile', :aggregate_failures do
        result = calculator.calculate_for_day_part('afternoon')

        expect(result).not_to be_nil
        expect(result[:day_part]).to eq('afternoon')
        expect(result[:counter]).to eq(2)
      end

      it 'calculates averages correctly', :aggregate_failures do
        result = calculator.calculate_for_day_part('afternoon')

        # (0.6 + 0.8) / 2 = 0.7
        expect(result[:danceability_average]).to eq(0.7)
        # (0.7 + 0.5) / 2 = 0.6
        expect(result[:energy_average]).to eq(0.6)
        # (120.0 + 130.0) / 2 = 125.0
        expect(result[:tempo]).to eq(125.0)
      end

      it 'calculates high percentages correctly', :aggregate_failures do
        result = calculator.calculate_for_day_part('afternoon')

        # Both songs have danceability > 0.5 threshold
        expect(result[:high_danceability_percentage]).to eq(1.0)
        # One song has speechiness > 0.33 threshold (speechy_song = 0.4)
        expect(result[:high_speechiness_percentage]).to eq(0.5)
        # One song has liveness > 0.8 threshold (speechy_song = 0.9)
        expect(result[:high_liveness_percentage]).to eq(0.5)
      end
    end

    context 'when no profiles exist for the day_part' do
      let(:calculator) { described_class.new(radio_station:, day_part: 'night') }

      it 'returns nil' do
        result = calculator.calculate_for_day_part('night')

        expect(result).to be_nil
      end
    end
  end

  describe '#calculate' do
    let(:radio_station) { create(:radio_station) }
    let(:song) { create(:song) }

    before do
      create(:music_profile, song:, danceability: 0.6)
      # Use 13 UTC which becomes 14 CET (afternoon)
      create(:air_play, song:, radio_station:, broadcasted_at: Time.utc(2026, 1, 2, 13, 0, 0))
    end

    context 'when day_part is specified' do
      let(:calculator) do
        described_class.new(
          radio_station:,
          day_part: 'afternoon',
          start_time: Time.utc(2026, 1, 1),
          end_time: Time.utc(2026, 1, 3)
        )
      end

      it 'returns profiles for that day_part only', :aggregate_failures do
        result = calculator.calculate

        expect(result.size).to eq(1)
        expect(result.first[:day_part]).to eq('afternoon')
      end
    end

    context 'when day_part is not specified' do
      let(:calculator) do
        described_class.new(
          radio_station:,
          start_time: Time.utc(2026, 1, 1),
          end_time: Time.utc(2026, 1, 3)
        )
      end

      it 'returns profiles for all day_parts with data' do
        result = calculator.calculate

        expect(result.map { |r| r[:day_part] }).to include('afternoon')
      end
    end
  end
end
