# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LyricsThemeBreakdownCalculator do
  let(:radio_station) { create(:radio_station) }
  let(:love_song) { create(:song) }
  let(:heartbreak_song) { create(:song) }
  let(:multi_theme_song) { create(:song) }
  let(:unanalyzed_song) { create(:song) }

  before do
    create(:lyric, song: love_song, themes: %w[love])
    create(:lyric, song: heartbreak_song, themes: %w[heartbreak])
    create(:lyric, song: multi_theme_song, themes: %w[love hope])
    create(:lyric, song: unanalyzed_song, themes: [])
  end

  describe '#calculate' do
    let(:calculator) { described_class.new(radio_station: radio_station, period: '7_days') }

    context 'when station has airplays with themed lyrics' do
      before do
        create(:air_play, radio_station: radio_station, song: love_song, broadcasted_at: 1.day.ago)
        create(:air_play, radio_station: radio_station, song: love_song, broadcasted_at: 2.days.ago)
        create(:air_play, radio_station: radio_station, song: heartbreak_song, broadcasted_at: 1.day.ago)
        create(:air_play, radio_station: radio_station, song: multi_theme_song, broadcasted_at: 1.day.ago)
        create(:air_play, radio_station: radio_station, song: unanalyzed_song, broadcasted_at: 1.day.ago)
      end

      it 'ranks themes by play count descending', :aggregate_failures do
        result = calculator.calculate
        expect(result.map { |t| t[:theme] }).to eq(%w[love heartbreak hope])
        expect(result.map { |t| t[:play_count] }).to eq([3, 1, 1])
      end

      it 'computes share against plays-with-themes (excludes plays with empty themes)' do
        result = calculator.calculate
        love_share = result.find { |t| t[:theme] == 'love' }[:share]
        expect(love_share).to be_within(0.001).of(0.75)
      end
    end

    context 'when station has no airplays in range' do
      it 'returns an empty array' do
        expect(calculator.calculate).to eq([])
      end
    end

    context 'when only unanalyzed plays fall in range' do
      before do
        create(:air_play, radio_station: radio_station, song: unanalyzed_song, broadcasted_at: 1.day.ago)
      end

      it 'returns an empty array' do
        expect(calculator.calculate).to eq([])
      end
    end

    context 'when more than 10 unique themes are present' do
      before do
        15.times do |i|
          song = create(:song)
          create(:lyric, song: song, themes: ["theme_#{format('%02d', i)}"])
          (15 - i).times { create(:air_play, radio_station: radio_station, song: song, broadcasted_at: 1.day.ago) }
        end
      end

      it 'limits to the top 10' do
        expect(calculator.calculate.size).to eq(10)
      end
    end

    context 'when no period is provided' do
      let(:calculator) { described_class.new(radio_station: radio_station, period: nil) }

      before do
        create(:air_play, radio_station: radio_station, song: love_song, broadcasted_at: 1.day.ago)
      end

      it 'defaults to 4 weeks and returns data' do
        expect(calculator.calculate).not_to be_empty
      end
    end
  end
end
