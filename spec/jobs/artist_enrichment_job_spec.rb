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

      it 'does not call Spotify' do
        job.perform(artist.id)
        expect(Spotify::ArtistFinder).not_to have_received(:new)
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

      it 'still records the check timestamp', :aggregate_failures do
        freeze_time = Time.current
        allow(Time).to receive(:current).and_return(freeze_time)

        job.perform(artist.id)

        expect(artist.reload.country_of_origin).to eq([])
        expect(artist.country_of_origin_checked_at).to be_within(1.second).of(freeze_time)
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

    context 'when artist was checked recently and Wikipedia had no nationality' do
      let(:artist) do
        create(:artist, id_on_spotify: 'spotify_123', country_of_origin: [], country_of_origin_checked_at: 2.days.ago)
      end

      it 'does not call Wikipedia again' do
        wikipedia_finder = instance_double(Wikipedia::ArtistFinder)
        allow(Wikipedia::ArtistFinder).to receive(:new).and_return(wikipedia_finder)

        job.perform(artist.id)

        expect(Wikipedia::ArtistFinder).not_to have_received(:new)
      end
    end

    context 'when artist was checked long ago and country is still empty' do
      let(:artist) do
        create(:artist, id_on_spotify: 'spotify_123', country_of_origin: [],
                        country_of_origin_checked_at: (described_class::RECHECK_AFTER + 1.day).ago)
      end

      it 'rechecks Wikipedia' do
        job.perform(artist.id)
        expect(artist.reload.country_of_origin).to eq(['United Kingdom'])
      end
    end
  end

  describe '.enqueue_all' do
    let!(:artist_without_country) { create(:artist, country_of_origin: []) }
    let!(:artist_with_country) { create(:artist, country_of_origin: ['Netherlands']) }
    let!(:artist_recently_checked) do
      create(:artist, country_of_origin: [], country_of_origin_checked_at: 1.day.ago)
    end
    let!(:artist_stale_check) do
      create(:artist, country_of_origin: [], country_of_origin_checked_at: (described_class::RECHECK_AFTER + 1.day).ago)
    end

    before do
      allow(described_class).to receive(:perform_in)
    end

    it 'enqueues jobs for artists without country_of_origin' do
      described_class.enqueue_all
      expect(described_class).to have_received(:perform_in).with(
        anything, artist_without_country.id
      )
    end

    it 'does not enqueue jobs for artists with country_of_origin' do
      described_class.enqueue_all
      expect(described_class).not_to have_received(:perform_in).with(anything, artist_with_country.id)
    end

    it 'does not enqueue jobs for artists checked within the recheck window' do
      described_class.enqueue_all
      expect(described_class).not_to have_received(:perform_in).with(anything, artist_recently_checked.id)
    end

    it 'enqueues jobs for artists whose check is older than the recheck window' do
      described_class.enqueue_all
      expect(described_class).to have_received(:perform_in).with(anything, artist_stale_check.id)
    end
  end
end
