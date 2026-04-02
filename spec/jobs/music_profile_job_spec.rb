# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MusicProfileJob do
  describe '#perform' do
    let(:song) { create(:song, id_on_spotify: '4iV5W9uYEdYUVa79Axb7Rh') }
    let(:radio_station) { create(:radio_station) }
    let(:job) { described_class.new }

    let(:audio_features) do
      {
        'danceability' => 0.65,
        'energy' => 0.72,
        'speechiness' => 0.08,
        'acousticness' => 0.25,
        'instrumentalness' => 0.02,
        'liveness' => 0.12,
        'valence' => 0.58,
        'tempo' => 120.5,
        'key' => 5,
        'mode' => 1,
        'loudness' => -5.5,
        'time_signature' => 4
      }
    end

    before do
      audio_feature_service = instance_double(Spotify::AudioFeature, audio_features: audio_features)
      allow(Spotify::AudioFeature).to receive(:new).and_return(audio_feature_service)
      # Stub the tag updating methods to avoid external API calls
      allow(job).to receive(:update_radio_station_tags)
    end

    context 'when song has Spotify ID and no music profile' do
      it 'creates a music profile' do
        expect do
          job.perform(song.id, radio_station.id)
        end.to change(MusicProfile, :count).by(1)
      end

      it 'creates music profile with correct attributes' do
        job.perform(song.id, radio_station.id)

        expect(song.reload.music_profile).to have_attributes(
          danceability: 0.65, energy: 0.72, tempo: 120.5,
          key: 5, mode: 1, loudness: -5.5, time_signature: 4
        )
      end

      it 'sets the hit_potential_score on the song' do
        job.perform(song.id, radio_station.id)

        expect(song.reload.hit_potential_score).to be_present
      end
    end

    context 'when song already has a music profile' do
      before { create(:music_profile, song:) }

      it 'does not create a duplicate' do
        expect do
          job.perform(song.id, radio_station.id)
        end.not_to change(MusicProfile, :count)
      end
    end

    context 'when song does not have Spotify ID' do
      let(:song) { create(:song, id_on_spotify: nil) }

      it 'does not create a music profile' do
        expect do
          job.perform(song.id, radio_station.id)
        end.not_to change(MusicProfile, :count)
      end
    end

    context 'when song does not exist' do
      it 'does not raise an error' do
        expect do
          job.perform(999_999, radio_station.id)
        end.not_to raise_error
      end
    end

    context 'when audio features are not available' do
      before do
        audio_feature_service = instance_double(Spotify::AudioFeature, audio_features: nil)
        allow(Spotify::AudioFeature).to receive(:new).and_return(audio_feature_service)
      end

      it 'does not create a music profile' do
        expect do
          job.perform(song.id, radio_station.id)
        end.not_to change(MusicProfile, :count)
      end
    end
  end

  describe '#update_radio_station_tags' do
    let(:artist_spotify_id) { 'artist_spotify_id_123' }
    let(:artist) { create(:artist, id_on_spotify: artist_spotify_id, genres: []) }
    let(:song) { create(:song, id_on_spotify: '4iV5W9uYEdYUVa79Axb7Rh', artists: [artist]) }
    let(:radio_station) { create(:radio_station) }
    let(:job) { described_class.new }

    let(:track_response) do
      { 'artists' => [{ 'id' => artist_spotify_id }] }
    end

    let(:artist_response) do
      { 'genres' => ['dutch pop', 'nederpop'], 'popularity' => 72, 'followers' => { 'total' => 150_000 } }
    end

    before do
      track_finder = instance_double(Spotify::TrackFinder::FindById, execute: track_response)
      allow(Spotify::TrackFinder::FindById).to receive(:new).and_return(track_finder)

      artist_finder = instance_double(Spotify::ArtistFinder, info: artist_response)
      allow(Spotify::ArtistFinder).to receive(:new).and_return(artist_finder)

      tag_record = instance_double(Tag, counter: 0, save: true)
      allow(tag_record).to receive(:counter=)
      allow(Tag).to receive(:find_or_initialize_by).and_return(tag_record)
    end

    context 'when artist exists with no genres and Spotify returns genres' do
      it 'stores genres on the artist' do
        job.send(:update_radio_station_tags, song.id_on_spotify, radio_station.id)

        expect(artist.reload.genres).to eq(['dutch pop', 'nederpop'])
      end

      it 'stores spotify_popularity on the artist' do
        job.send(:update_radio_station_tags, song.id_on_spotify, radio_station.id)

        expect(artist.reload.spotify_popularity).to eq(72)
      end

      it 'stores spotify_followers_count on the artist' do
        job.send(:update_radio_station_tags, song.id_on_spotify, radio_station.id)

        expect(artist.reload.spotify_followers_count).to eq(150_000)
      end
    end

    context 'when artist already has genres' do
      before { artist.update(genres: ['existing genre']) }

      it 'does not overwrite existing genres' do
        job.send(:update_radio_station_tags, song.id_on_spotify, radio_station.id)

        expect(artist.reload.genres).to eq(['existing genre'])
      end
    end

    context 'when Spotify returns no genres for the artist' do
      let(:artist_response) { { 'genres' => [], 'popularity' => nil, 'followers' => nil } }

      it 'does not update the artist genres' do
        job.send(:update_radio_station_tags, song.id_on_spotify, radio_station.id)

        expect(artist.reload.genres).to eq([])
      end
    end
  end
end
