# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SongLifecycleDetector do
  describe '#detect' do
    let(:radio_station) { create(:radio_station) }
    let(:song) { create(:song) }

    context 'when song has insufficient data' do
      before do
        create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 1.day.ago)
      end

      it 'returns nil' do
        expect(described_class.new(song).detect).to be_nil
      end
    end

    context 'when song is in rise phase' do
      before do
        create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 3.weeks.ago)
        3.times { create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 2.weeks.ago) }
        6.times { create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 1.week.ago) }
        10.times { create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 1.day.ago) }
      end

      it 'detects the rise phase', :aggregate_failures do
        result = described_class.new(song).detect

        expect(result[:phase]).to eq(:rise)
        expect(result[:weekly_counts]).to be_a(Hash)
        expect(result[:peak_count]).to be_positive
      end
    end

    context 'when song is in decline phase' do
      before do
        2.times { create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 8.weeks.ago) }
        5.times { create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 7.weeks.ago) }
        10.times { create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 6.weeks.ago) }
        8.times { create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 5.weeks.ago) }
        4.times { create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 4.weeks.ago) }
        2.times { create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 3.weeks.ago) }
        create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 2.weeks.ago)
      end

      it 'detects the decline phase', :aggregate_failures do
        result = described_class.new(song).detect

        expect(result[:phase]).to eq(:decline)
        expect(result[:days_to_peak]).to be_positive
      end
    end

    context 'when filtering by radio station' do
      let(:other_station) { create(:radio_station) }

      before do
        2.times { create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 3.weeks.ago) }
        5.times { create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 1.day.ago) }
        20.times { create(:air_play, song: song, radio_station: other_station, broadcasted_at: 3.weeks.ago) }
      end

      it 'only considers airplays from specified stations', :aggregate_failures do
        result = described_class.new(song, radio_station_ids: [radio_station.id]).detect
        total_plays = result[:weekly_counts].values.sum

        expect(total_plays).to eq(7)
      end
    end
  end
end
