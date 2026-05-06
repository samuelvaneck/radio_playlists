# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HitPotentialCalculator do
  describe '#calculate' do
    context 'when song has no music profile' do
      let(:song) { build(:song) }

      it 'returns nil' do
        expect(described_class.new(song).calculate).to be_nil
      end
    end

    context 'when song has typical hit features and popular artist' do
      let(:artist) { build(:artist, spotify_popularity: 85, spotify_followers_count: 5_000_000, lastfm_listeners: 2_000_000) }
      let(:song) do
        build(:song, artists: [artist], popularity: 80, lastfm_listeners: 1_500_000,
                     lastfm_playcount: 10_000_000, release_date: 3.months.ago.to_date)
      end
      let(:music_profile) do
        build(:music_profile, song: song, danceability: 0.64, energy: 0.68, valence: 0.52,
                              acousticness: 0.15, instrumentalness: 0.02, speechiness: 0.08,
                              liveness: 0.17, tempo: 120.0, loudness: -6.0)
      end

      before { allow(song).to receive(:music_profile).and_return(music_profile) }

      it 'returns a high score' do
        expect(described_class.new(song).calculate).to be > 75.0
      end
    end

    context 'when song has poor audio features and unknown artist' do
      let(:artist) { build(:artist, spotify_popularity: nil, spotify_followers_count: nil, lastfm_listeners: nil) }
      let(:song) do
        build(:song, artists: [artist], popularity: nil, lastfm_listeners: nil,
                     lastfm_playcount: nil, release_date: 10.years.ago.to_date)
      end
      let(:music_profile) do
        build(:music_profile, song: song, danceability: 0.15, energy: 0.10, valence: 0.10,
                              acousticness: 0.95, instrumentalness: 0.90, speechiness: 0.80,
                              liveness: 0.90, tempo: 40.0, loudness: -30.0)
      end

      before { allow(song).to receive(:music_profile).and_return(music_profile) }

      it 'returns a low score' do
        expect(described_class.new(song).calculate).to be < 20.0
      end
    end

    context 'when song has no artist' do
      let(:song) { build(:song, artists: [], popularity: 50, release_date: 1.year.ago.to_date) }
      let(:music_profile) { build(:music_profile, song: song) }

      before { allow(song).to receive(:music_profile).and_return(music_profile) }

      it 'returns a score between 0 and 100' do
        expect(described_class.new(song).calculate).to be_between(0.0, 100.0)
      end
    end

    context 'when song has no release date' do
      let(:song) { build(:song, release_date: nil) }
      let(:music_profile) { build(:music_profile, song: song) }

      before { allow(song).to receive(:music_profile).and_return(music_profile) }

      it 'uses a neutral recency score' do
        expect(described_class.new(song).calculate).to be_between(0.0, 100.0)
      end
    end

    context 'when song has a recent release date' do
      let(:old_song) { build(:song, release_date: 4.years.ago.to_date) }
      let(:new_song) { build(:song, release_date: 1.week.ago.to_date) }
      let(:old_profile) { build(:music_profile, song: old_song) }
      let(:new_profile) { build(:music_profile, song: new_song) }

      before do
        allow(old_song).to receive(:music_profile).and_return(old_profile)
        allow(new_song).to receive(:music_profile).and_return(new_profile)
      end

      it 'scores the newer song higher' do
        old_score = described_class.new(old_song).calculate
        new_score = described_class.new(new_song).calculate
        expect(new_score).to be > old_score
      end
    end

    it 'returns a score between 0 and 100' do
      song = build(:song)
      music_profile = build(:music_profile, song: song)
      allow(song).to receive(:music_profile).and_return(music_profile)

      expect(described_class.new(song).calculate).to be_between(0.0, 100.0)
    end

    context 'when comparing songs with different lyrics sentiment' do
      let(:positive_song) { build(:song) }
      let(:negative_song) { build(:song) }
      let(:positive_lyric) { build(:lyric, sentiment: 0.9) }
      let(:negative_lyric) { build(:lyric, sentiment: -0.9) }

      before do
        allow(positive_song).to receive_messages(music_profile: build(:music_profile, song: positive_song),
                                                 lyric: positive_lyric)
        allow(negative_song).to receive_messages(music_profile: build(:music_profile, song: negative_song),
                                                 lyric: negative_lyric)
      end

      it 'scores the positive-sentiment song higher' do
        expect(described_class.new(positive_song).calculate).to be > described_class.new(negative_song).calculate
      end
    end
  end

  describe '#breakdown' do
    context 'when song has no music profile' do
      let(:song) { build(:song) }

      it 'returns nil' do
        expect(described_class.new(song).breakdown).to be_nil
      end
    end

    context 'when song has a music profile' do
      let(:artist) { build(:artist, spotify_popularity: 85, spotify_followers_count: 5_000_000, lastfm_listeners: 2_000_000) }
      let(:song) do
        build(:song, artists: [artist], popularity: 80, lastfm_listeners: 1_500_000,
                     lastfm_playcount: 10_000_000, release_date: 3.months.ago.to_date)
      end
      let(:music_profile) do
        build(:music_profile, song: song, danceability: 0.64, energy: 0.68, valence: 0.52,
                              acousticness: 0.15, instrumentalness: 0.02, speechiness: 0.08,
                              liveness: 0.17, tempo: 120.0, loudness: -6.0)
      end

      before { allow(song).to receive(:music_profile).and_return(music_profile) }

      it 'returns all signal categories', :aggregate_failures do
        result = described_class.new(song).breakdown
        expect(result).to include(:audio_features, :artist_popularity, :engagement, :release_recency,
                                  :lyrics_sentiment, :audio_features_detail)
      end

      it 'has category contributions that sum to the total score', :aggregate_failures do
        calculator = described_class.new(song)
        result = calculator.breakdown
        category_sum = result[:audio_features] + result[:artist_popularity] + result[:engagement] +
                       result[:release_recency] + result[:lyrics_sentiment]
        expect(category_sum).to be_within(0.1).of(calculator.calculate)
      end

      it 'includes per-audio-feature detail' do
        result = described_class.new(song).breakdown
        expect(result[:audio_features_detail].keys).to match_array(HitPotentialCalculator::AUDIO_FEATURE_WEIGHTS.keys)
      end

      it 'has audio feature details that sum to the audio features category' do
        result = described_class.new(song).breakdown
        detail_sum = result[:audio_features_detail].values.sum
        expect(detail_sum).to be_within(0.01).of(result[:audio_features])
      end
    end
  end
end
