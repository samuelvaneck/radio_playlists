# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArtistEnrichmentJob do
  describe '#perform' do
    let(:artist) { create(:artist, id_on_spotify: 'spotify_123', country_of_origin: []) }
    let(:job) { described_class.new }

    let(:wikipedia_info) do
      {
        'general_info' => {
          'nationality' => ['United Kingdom']
        }
      }
    end

    let(:spotify_artist_response) do
      { 'popularity' => 85, 'followers' => { 'total' => 500_000 } }
    end

    before do
      allow_any_instance_of(Wikipedia::ArtistFinder).to receive(:get_info).and_return(wikipedia_info) # rubocop:disable RSpec/AnyInstance
      artist_finder = instance_double(Spotify::ArtistFinder, info: spotify_artist_response)
      allow(Spotify::ArtistFinder).to receive(:new).and_return(artist_finder)
    end

    context 'when artist has empty country_of_origin and Spotify ID' do
      it 'stores country_of_origin from Wikipedia' do
        job.perform(artist.id)
        expect(artist.reload.country_of_origin).to eq(['United Kingdom'])
      end

      it 'stores spotify_popularity' do
        job.perform(artist.id)
        expect(artist.reload.spotify_popularity).to eq(85)
      end

      it 'stores spotify_followers_count' do
        job.perform(artist.id)
        expect(artist.reload.spotify_followers_count).to eq(500_000)
      end
    end

    context 'when artist already has country_of_origin' do
      let(:artist) { create(:artist, id_on_spotify: 'spotify_123', country_of_origin: ['Netherlands']) }

      it 'does not overwrite country_of_origin' do
        job.perform(artist.id)
        expect(artist.reload.country_of_origin).to eq(['Netherlands'])
      end
    end

    context 'when Wikipedia returns no data' do
      before do
        allow_any_instance_of(Wikipedia::ArtistFinder).to receive(:get_info).and_return(nil) # rubocop:disable RSpec/AnyInstance
      end

      it 'does not update country_of_origin' do
        job.perform(artist.id)
        expect(artist.reload.country_of_origin).to eq([])
      end
    end

    context 'when artist has no Spotify ID' do
      let(:artist) { create(:artist, id_on_spotify: nil, country_of_origin: []) }

      it 'does not update Spotify metrics' do
        job.perform(artist.id)
        expect(artist.reload.spotify_popularity).to be_nil
      end
    end

    context 'when artist does not exist' do
      it 'does not raise an error' do
        expect { job.perform(999_999) }.not_to raise_error
      end
    end
  end

  describe '.enqueue_all' do
    let!(:artist_without_country) { create(:artist, country_of_origin: []) }
    let!(:artist_with_country) { create(:artist, country_of_origin: ['Netherlands']) }

    before do
      allow(described_class).to receive(:perform_async)
    end

    it 'enqueues jobs for artists without country_of_origin' do
      described_class.enqueue_all
      expect(described_class).to have_received(:perform_async).with(artist_without_country.id)
    end

    it 'does not enqueue jobs for artists with country_of_origin' do
      described_class.enqueue_all
      expect(described_class).not_to have_received(:perform_async).with(artist_with_country.id)
    end
  end
end
