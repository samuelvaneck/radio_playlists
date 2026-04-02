# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HitPotentialCalculator do
  describe '#calculate' do
    context 'when music profile is nil' do
      it 'returns nil' do
        expect(described_class.new(nil).calculate).to be_nil
      end
    end

    context 'when music profile has typical hit features' do
      let(:music_profile) do
        build(:music_profile,
              danceability: 0.64,
              energy: 0.68,
              valence: 0.52,
              acousticness: 0.15,
              instrumentalness: 0.02,
              speechiness: 0.08,
              liveness: 0.17,
              tempo: 120.0,
              loudness: -6.0)
      end

      it 'returns a high score' do
        score = described_class.new(music_profile).calculate
        expect(score).to be > 90.0
      end
    end

    context 'when music profile has non-hit features' do
      let(:music_profile) do
        build(:music_profile,
              danceability: 0.15,
              energy: 0.10,
              valence: 0.10,
              acousticness: 0.95,
              instrumentalness: 0.90,
              speechiness: 0.80,
              liveness: 0.90,
              tempo: 40.0,
              loudness: -30.0)
      end

      it 'returns a low score' do
        score = described_class.new(music_profile).calculate
        expect(score).to be < 30.0
      end
    end

    context 'when music profile has average features' do
      let(:music_profile) do
        build(:music_profile,
              danceability: 0.50,
              energy: 0.50,
              valence: 0.50,
              acousticness: 0.30,
              instrumentalness: 0.10,
              speechiness: 0.10,
              liveness: 0.20,
              tempo: 110.0,
              loudness: -8.0)
      end

      it 'returns a moderate score' do
        score = described_class.new(music_profile).calculate
        expect(score).to be_between(40.0, 90.0)
      end
    end

    it 'returns a score between 0 and 100' do
      music_profile = build(:music_profile)
      score = described_class.new(music_profile).calculate
      expect(score).to be_between(0.0, 100.0)
    end
  end
end
