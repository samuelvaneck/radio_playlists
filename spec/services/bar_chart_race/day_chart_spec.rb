# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BarChartRace::DayChart do
  let(:radio_station) { create(:radio_station) }
  let(:song_a) { create(:song, title: 'Song A') }
  let(:song_b) { create(:song, title: 'Song B') }
  let(:song_c) { create(:song, title: 'Song C') }

  describe '#frames' do
    context 'with period parameter' do
      let(:params) { { period: 'day' } }
      let(:chart) { described_class.new(radio_station:, params:) }

      before do
        5.times { |i| create(:air_play, song: song_a, radio_station:, broadcasted_at: 2.hours.ago + i.minutes) }
        3.times { |i| create(:air_play, song: song_b, radio_station:, broadcasted_at: 2.hours.ago + i.minutes) }
        create(:air_play, song: song_c, radio_station:, broadcasted_at: 2.hours.ago)
      end

      it 'returns a single frame for a single day' do
        expect(chart.frames.size).to eq(1)
      end

      it 'ranks songs by play count', :aggregate_failures do
        frame = chart.frames.first
        entries = frame[:entries]

        expect(entries.first[:song][:title]).to eq('Song A')
        expect(entries.first[:count]).to eq(5)
        expect(entries.first[:position]).to eq(1)
        expect(entries.second[:song][:title]).to eq('Song B')
        expect(entries.second[:count]).to eq(3)
        expect(entries.second[:position]).to eq(2)
      end

      it 'includes song details in entries', :aggregate_failures do
        entry = chart.frames.first[:entries].first

        expect(entry[:song]).to include(:id, :title, :spotify_artwork_url, :artists)
      end

      it 'includes date in the frame' do
        expect(chart.frames.first[:date]).to match(/\A\d{4}-\d{2}-\d{2}\z/)
      end
    end

    context 'with week period' do
      let(:params) { { period: 'week' } }
      let(:chart) { described_class.new(radio_station:, params:) }

      before do
        3.times { |i| create(:air_play, song: song_a, radio_station:, broadcasted_at: 3.days.ago.midday + i.minutes) }
        2.times { |i| create(:air_play, song: song_b, radio_station:, broadcasted_at: 1.day.ago.midday + i.minutes) }
      end

      it 'returns one frame per day with plays in the window', :aggregate_failures do
        frames = chart.frames

        expect(frames.size).to be >= 2
      end

      it 'accumulates counts across the rolling window', :aggregate_failures do
        frames = chart.frames
        last_frame = frames.last

        song_a_entry = last_frame[:entries].find { |e| e[:song][:title] == 'Song A' }
        song_b_entry = last_frame[:entries].find { |e| e[:song][:title] == 'Song B' }

        expect(song_a_entry[:count]).to eq(3)
        expect(song_b_entry[:count]).to eq(2)
      end
    end

    context 'with rolling window smoothing' do
      let(:params) { { start_time: 10.days.ago.strftime('%Y-%m-%dT%H:%M'), end_time: Time.current.strftime('%Y-%m-%dT%H:%M') } }
      let(:chart) { described_class.new(radio_station:, params:) }

      before do
        5.times { |i| create(:air_play, song: song_a, radio_station:, broadcasted_at: 8.days.ago.midday + i.minutes) }
        3.times { |i| create(:air_play, song: song_b, radio_station:, broadcasted_at: 3.days.ago.midday + i.minutes) }
      end

      it 'includes past plays within the 7-day rolling window', :aggregate_failures do
        frame_3_days_ago = chart.frames.find { |f| f[:date] == 3.days.ago.to_date.to_s }

        song_b_entry = frame_3_days_ago[:entries].find { |e| e[:song][:title] == 'Song B' }
        expect(song_b_entry[:count]).to eq(3)
      end

      it 'drops plays older than the rolling window', :aggregate_failures do
        today_frame = chart.frames.find { |f| f[:date] == Time.current.to_date.to_s }

        if today_frame
          song_a_entry = today_frame[:entries].find { |e| e[:song][:title] == 'Song A' }
          expect(song_a_entry).to be_nil
        end
      end
    end

    context 'with more than 10 songs' do
      let(:params) { { period: 'day' } }
      let(:chart) { described_class.new(radio_station:, params:) }

      before do
        12.times do |i|
          song = create(:song, title: "Song #{i}")
          create(:air_play, song:, radio_station:, broadcasted_at: 2.hours.ago + i.minutes)
        end
      end

      it 'limits to top 10 per frame' do
        expect(chart.frames.first[:entries].size).to eq(10)
      end
    end

    context 'with no air plays' do
      let(:params) { { period: 'day' } }
      let(:chart) { described_class.new(radio_station:, params:) }

      it 'returns empty array' do
        expect(chart.frames).to be_empty
      end
    end

    context 'with custom date range' do
      let(:params) { { start_time: 4.days.ago.strftime('%Y-%m-%dT%H:%M'), end_time: 1.day.ago.strftime('%Y-%m-%dT%H:%M') } }
      let(:chart) { described_class.new(radio_station:, params:) }

      before do
        3.times { |i| create(:air_play, song: song_a, radio_station:, broadcasted_at: 2.days.ago.midday + i.minutes) }
        2.times { |i| create(:air_play, song: song_a, radio_station:, broadcasted_at: 10.days.ago.midday + i.minutes) }
      end

      it 'only includes plays within the date range' do
        frame = chart.frames.first

        expect(frame[:entries].first[:count]).to eq(3)
      end
    end
  end

  describe '#meta' do
    let(:params) { { period: 'day' } }
    let(:chart) { described_class.new(radio_station:, params:) }

    it 'returns type, period, and time range', :aggregate_failures do
      meta = chart.meta

      expect(meta[:type]).to eq('day_chart')
      expect(meta[:period]).to eq('day')
      expect(meta[:start_time]).to be_present
      expect(meta[:end_time]).to be_present
    end

    it 'returns ISO8601 formatted times', :aggregate_failures do
      meta = chart.meta

      expect { Time.iso8601(meta[:start_time]) }.not_to raise_error
      expect { Time.iso8601(meta[:end_time]) }.not_to raise_error
    end
  end
end
