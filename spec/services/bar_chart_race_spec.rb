# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BarChartRace do
  let(:radio_station) { create(:radio_station) }
  let(:song_a) { create(:song, title: 'Song A') }
  let(:song_b) { create(:song, title: 'Song B') }
  let(:song_c) { create(:song, title: 'Song C') }

  describe '#frames' do
    context 'with period parameter' do
      let(:params) { { period: 'week' } }
      let(:race) { described_class.new(radio_station:, params:) }

      before do
        5.times { |i| create(:air_play, song: song_a, radio_station:, broadcasted_at: 2.days.ago.midday + i.minutes) }
        3.times { |i| create(:air_play, song: song_b, radio_station:, broadcasted_at: 2.days.ago.midday + i.minutes) }
        2.times { |i| create(:air_play, song: song_b, radio_station:, broadcasted_at: 1.day.ago.midday + i.minutes) }
      end

      it 'returns frames as a non-empty array' do
        expect(race.frames).not_to be_empty
      end

      it 'ranks songs by cumulative count', :aggregate_failures do
        frames = race.frames
        last_frame = frames.last

        first_entry = last_frame[:entries].first
        expect(first_entry[:song][:title]).to eq('Song B')
        expect(first_entry[:count]).to eq(5)
        expect(first_entry[:position]).to eq(1)
      end

      it 'includes song details in entries', :aggregate_failures do
        frames = race.frames
        entry = frames.first[:entries].first

        expect(entry[:song]).to include(:id, :title, :spotify_artwork_url, :artists)
      end

      it 'includes date in each frame' do
        frames = race.frames

        expect(frames.first[:date]).to match(/\A\d{4}-\d{2}-\d{2}\z/)
      end
    end

    context 'with cumulative counting across days' do
      let(:params) { { period: 'week' } }
      let(:race) { described_class.new(radio_station:, params:) }

      before do
        3.times { |i| create(:air_play, song: song_a, radio_station:, broadcasted_at: 3.days.ago.midday + i.minutes) }
        2.times { |i| create(:air_play, song: song_a, radio_station:, broadcasted_at: 2.days.ago.midday + i.minutes) }
      end

      it 'accumulates counts across days' do
        frames = race.frames
        last_frame = frames.last

        expect(last_frame[:entries].first[:count]).to eq(5)
      end
    end

    context 'with more than 10 songs' do
      let(:params) { { period: 'week' } }
      let(:race) { described_class.new(radio_station:, params:) }

      before do
        12.times do |i|
          song = create(:song, title: "Song #{i}")
          create(:air_play, song:, radio_station:, broadcasted_at: 1.day.ago.midday + i.minutes)
        end
      end

      it 'limits to top 10 per frame' do
        frames = race.frames

        expect(frames.last[:entries].size).to eq(10)
      end
    end

    context 'with no air plays' do
      let(:params) { { period: 'week' } }
      let(:race) { described_class.new(radio_station:, params:) }

      it 'returns empty array' do
        expect(race.frames).to be_empty
      end
    end

    context 'with custom date range' do
      let(:params) { { start_time: 4.days.ago.strftime('%Y-%m-%dT%H:%M'), end_time: 1.day.ago.strftime('%Y-%m-%dT%H:%M') } }
      let(:race) { described_class.new(radio_station:, params:) }

      before do
        3.times { |i| create(:air_play, song: song_a, radio_station:, broadcasted_at: 2.days.ago.midday + i.minutes) }
        2.times { |i| create(:air_play, song: song_a, radio_station:, broadcasted_at: 10.days.ago.midday + i.minutes) }
      end

      it 'only includes plays within the date range' do
        frames = race.frames
        total_count = frames.last[:entries].first[:count]

        expect(total_count).to eq(3)
      end
    end
  end

  describe '#meta' do
    let(:params) { { period: 'week' } }
    let(:race) { described_class.new(radio_station:, params:) }

    it 'returns period and time range', :aggregate_failures do
      meta = race.meta

      expect(meta[:period]).to eq('week')
      expect(meta[:start_time]).to be_present
      expect(meta[:end_time]).to be_present
    end

    it 'returns ISO8601 formatted times', :aggregate_failures do
      meta = race.meta

      expect { Time.iso8601(meta[:start_time]) }.not_to raise_error
      expect { Time.iso8601(meta[:end_time]) }.not_to raise_error
    end
  end
end
