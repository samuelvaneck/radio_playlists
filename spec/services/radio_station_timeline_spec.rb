# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RadioStationTimeline do
  let(:radio_station) { create(:radio_station) }
  let(:popular_song) { create(:song, title: 'Popular Song') }
  let(:less_popular_song) { create(:song, title: 'Less Popular Song') }

  describe '#songs' do
    context 'with period parameter' do
      let(:params) { { period: 'week' } }
      let(:timeline) { described_class.new(radio_station:, params:) }

      before do
        5.times do |i|
          create(:air_play, song: popular_song, radio_station:, broadcasted_at: 2.days.ago + i.minutes)
        end
        2.times do |i|
          create(:air_play, song: less_popular_song, radio_station:, broadcasted_at: 3.days.ago + i.minutes)
        end
      end

      it 'returns songs ordered by play count' do
        songs = timeline.songs

        expect(songs.first.id).to eq(popular_song.id)
      end

      it 'includes counter attribute' do
        songs = timeline.songs

        expect(songs.first.counter).to eq(5)
      end

      it 'attaches daily_plays method to songs' do
        songs = timeline.songs

        expect(songs.first).to respond_to(:daily_plays)
      end

      it 'returns daily play counts as hash', :aggregate_failures do
        songs = timeline.songs
        daily_plays = songs.first.daily_plays

        expect(daily_plays).to be_a(Hash)
        expect(daily_plays.values.sum).to eq(5)
      end
    end

    context 'with custom date range' do
      let(:params) { { start_time: 4.days.ago.strftime('%Y-%m-%dT%H:%M'), end_time: 1.day.ago.strftime('%Y-%m-%dT%H:%M') } }
      let(:timeline) { described_class.new(radio_station:, params:) }

      before do
        3.times do |i|
          create(:air_play, song: popular_song, radio_station:, broadcasted_at: 2.days.ago + i.minutes)
        end
        2.times do |i|
          create(:air_play, song: popular_song, radio_station:, broadcasted_at: 10.days.ago + i.minutes)
        end
      end

      it 'only includes plays within the date range' do
        songs = timeline.songs

        expect(songs.first.counter).to eq(3)
      end
    end

    context 'with no matching air plays' do
      let(:params) { { period: 'week' } }
      let(:timeline) { described_class.new(radio_station:, params:) }

      it 'returns empty collection' do
        songs = timeline.songs

        expect(songs).to be_empty
      end
    end

    context 'with multiple days of plays' do
      let(:params) { { period: 'week' } }
      let(:timeline) { described_class.new(radio_station:, params:) }

      before do
        3.times do |i|
          create(:air_play, song: popular_song, radio_station:, broadcasted_at: 1.day.ago.midday + i.minutes)
        end
        2.times do |i|
          create(:air_play, song: popular_song, radio_station:, broadcasted_at: 2.days.ago.midday + i.minutes)
        end
        create(:air_play, song: popular_song, radio_station:, broadcasted_at: 3.days.ago.midday)
      end

      it 'groups plays by day correctly', :aggregate_failures do
        songs = timeline.songs
        daily_plays = songs.first.daily_plays

        expect(daily_plays.keys.size).to eq(3)
        expect(daily_plays[1.day.ago.to_date.to_s]).to eq(3)
        expect(daily_plays[2.days.ago.to_date.to_s]).to eq(2)
        expect(daily_plays[3.days.ago.to_date.to_s]).to eq(1)
      end
    end
  end

  describe '#meta' do
    let(:params) { { period: 'week' } }
    let(:timeline) { described_class.new(radio_station:, params:) }

    it 'returns period in meta', :aggregate_failures do
      meta = timeline.meta

      expect(meta[:period]).to eq('week')
      expect(meta[:start_time]).to be_present
      expect(meta[:end_time]).to be_present
    end

    it 'returns ISO8601 formatted times', :aggregate_failures do
      meta = timeline.meta

      expect { Time.iso8601(meta[:start_time]) }.not_to raise_error
      expect { Time.iso8601(meta[:end_time]) }.not_to raise_error
    end
  end
end
