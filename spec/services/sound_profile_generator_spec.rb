# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SoundProfileGenerator do
  let(:radio_station) { create(:radio_station) }
  let(:start_time) { Time.utc(2026, 1, 1) }
  let(:end_time) { Time.utc(2026, 2, 1) }
  let(:generator) { described_class.new(radio_station:, start_time:, end_time:) }

  describe '#generate' do
    context 'when station has airplay data' do
      let(:danceable_song) { create(:song, release_date: Date.new(2020, 6, 1), lastfm_tags: %w[electronic upbeat]) }
      let(:mellow_song) { create(:song, release_date: Date.new(2023, 3, 15), lastfm_tags: %w[electronic pop]) }
      let(:artist) { create(:artist, genres: %w[pop dance], lastfm_tags: %w[electronic upbeat]) }
      let(:result) { generator.generate }

      before do
        danceable_song.artists << artist
        mellow_song.artists << artist

        create(:music_profile, song: danceable_song, danceability: 0.8, energy: 0.7, speechiness: 0.1,
                               acousticness: 0.2, instrumentalness: 0.05, liveness: 0.1, valence: 0.7, tempo: 125.0)
        create(:music_profile, song: mellow_song, danceability: 0.6, energy: 0.5, speechiness: 0.3,
                               acousticness: 0.4, instrumentalness: 0.1, liveness: 0.2, valence: 0.5, tempo: 110.0)

        create(:air_play, song: danceable_song, radio_station:, broadcasted_at: Time.utc(2026, 1, 15, 14, 0, 0))
        create(:air_play, song: mellow_song, radio_station:, broadcasted_at: Time.utc(2026, 1, 15, 15, 0, 0))
      end

      it 'includes radio station info and sample size', :aggregate_failures do
        expect(result[:radio_station][:id]).to eq(radio_station.id)
        expect(result[:radio_station][:name]).to eq(radio_station.name)
        expect(result[:sample_size]).to eq(2)
      end

      it 'returns all expected keys', :aggregate_failures do
        expect(result[:audio_features]).to be_a(Hash)
        expect(result[:tempo]).to be_a(Hash)
        expect(result[:top_genres]).to be_an(Array)
        expect(result[:top_tags]).to be_an(Array)
        expect(result[:release_decade_distribution]).to be_an(Array)
        expect(result[:release_year_range]).to be_a(Hash)
        expect(result[:description_en]).to be_a(String)
        expect(result[:description_nl]).to be_a(String)
      end

      it 'calculates audio feature averages', :aggregate_failures do
        expect(result[:audio_features]['danceability'][:average]).to eq(0.7)
        expect(result[:audio_features]['energy'][:average]).to eq(0.6)
        expect(result[:tempo][:average]).to eq(117.5)
      end

      it 'assigns feature labels', :aggregate_failures do
        expect(result[:audio_features]['danceability'][:label]).to eq('very danceable')
        expect(result[:audio_features]['energy'][:label]).to eq('high-energy')
        expect(result[:tempo][:label]).to eq('mid-tempo')
      end

      it 'returns top genres' do
        genre_names = result[:top_genres].map { |g| g[:name] }
        expect(genre_names).to include('pop', 'dance')
      end

      it 'returns top tags' do
        tag_names = result[:top_tags].map { |t| t[:name] }
        expect(tag_names).to include('electronic', 'upbeat')
      end

      it 'returns release decade distribution' do
        decades = result[:release_decade_distribution].map { |d| d[:decade] }
        expect(decades).to include('2020s')
      end

      it 'returns release year range', :aggregate_failures do
        expect(result[:release_year_range][:from]).to be_a(Integer)
        expect(result[:release_year_range][:to]).to be_a(Integer)
      end

      it 'generates bilingual descriptions', :aggregate_failures do
        expect(result[:description_en]).to include(radio_station.name)
        expect(result[:description_nl]).to include(radio_station.name)
      end
    end

    context 'when station has no airplay data' do
      it 'returns empty collections', :aggregate_failures do
        result = generator.generate

        expect(result[:sample_size]).to eq(0)
        expect(result[:top_genres]).to be_empty
        expect(result[:top_tags]).to be_empty
        expect(result[:release_decade_distribution]).to be_empty
        expect(result[:release_year_range]).to be_nil
      end
    end
  end

  describe '#release_year_range' do
    context 'with weighted song distribution' do
      before do
        # Simulate a station heavy on 90s music: 5 songs from 90s, 3 from 2020s, 2 from 80s
        { 1985 => 1, 1988 => 1, 1992 => 2, 1995 => 2, 1999 => 1, 2020 => 1, 2022 => 1, 2024 => 1 }.each do |year, count|
          count.times do
            song = create(:song, release_date: Date.new(year, 1, 1))
            create(:air_play, song:, radio_station:, broadcasted_at: Time.utc(2026, 1, 15, 12, 0, 0))
          end
        end
      end

      it 'uses weighted percentiles based on song counts', :aggregate_failures do
        result = generator.generate
        range = result[:release_year_range]

        expect(range[:from]).to be_a(Integer)
        expect(range[:to]).to be_a(Integer)
        expect(range[:median_year]).to be_a(Integer)
        expect(range[:peak_decades]).to be_an(Array)
        expect(range[:era_description_en]).to be_a(String)
        expect(range[:era_description_nl]).to be_a(String)
      end
    end
  end
end
