# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MusicProfileJob do
  describe '#perform' do
    let(:song) { create(:song, id_on_spotify: '4iV5W9uYEdYUVa79Axb7Rh') }
    let(:radio_station) { create(:radio_station) }

    let(:audio_features) do
      {
        'danceability' => 0.65,
        'energy' => 0.72,
        'speechiness' => 0.08,
        'acousticness' => 0.25,
        'instrumentalness' => 0.02,
        'liveness' => 0.12,
        'valence' => 0.58,
        'tempo' => 120.5
      }
    end

    before do
      allow_any_instance_of(Spotify::AudioFeature).to receive(:audio_features).and_return(audio_features)
      # Stub the tag updating methods to avoid external API calls
      allow_any_instance_of(described_class).to receive(:update_radio_station_tags)
    end

    context 'when song has Spotify ID and no music profile' do
      it 'creates a music profile' do
        expect {
          described_class.new.perform(song.id, radio_station.id)
        }.to change { MusicProfile.count }.by(1)
      end

      it 'creates music profile with correct attributes' do
        described_class.new.perform(song.id, radio_station.id)

        profile = song.reload.music_profile
        expect(profile.danceability).to eq(0.65)
        expect(profile.energy).to eq(0.72)
        expect(profile.tempo).to eq(120.5)
      end
    end

    context 'when song already has a music profile' do
      before { create(:music_profile, song:) }

      it 'does not create a duplicate' do
        expect {
          described_class.new.perform(song.id, radio_station.id)
        }.not_to change { MusicProfile.count }
      end
    end

    context 'when song does not have Spotify ID' do
      let(:song) { create(:song, id_on_spotify: nil) }

      it 'does not create a music profile' do
        expect {
          described_class.new.perform(song.id, radio_station.id)
        }.not_to change { MusicProfile.count }
      end
    end

    context 'when song does not exist' do
      it 'does not raise an error' do
        expect {
          described_class.new.perform(999_999, radio_station.id)
        }.not_to raise_error
      end
    end

    context 'when audio features are not available' do
      before do
        allow_any_instance_of(Spotify::AudioFeature).to receive(:audio_features).and_return(nil)
      end

      it 'does not create a music profile' do
        expect {
          described_class.new.perform(song.id, radio_station.id)
        }.not_to change { MusicProfile.count }
      end
    end
  end
end
