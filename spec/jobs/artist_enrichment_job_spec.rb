# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArtistEnrichmentJob do
  describe '#perform' do
    let(:artist) { create(:artist, id_on_spotify: 'spotify_123', country_code: nil) }
    let(:job) { described_class.new }

    let(:spotify_artist_response) do
      { 'popularity' => 85, 'followers' => { 'total' => 500_000 } }
    end

    before do
      country_finder = instance_double(MusicBrainz::ArtistCountryFinder, call: 'GB')
      allow(MusicBrainz::ArtistCountryFinder).to receive(:new).and_return(country_finder)
      artist_finder = instance_double(Spotify::ArtistFinder, info: spotify_artist_response)
      allow(Spotify::ArtistFinder).to receive(:new).and_return(artist_finder)
    end

    context 'when artist has no country_code and a Spotify ID' do
      it 'stores country_code from MusicBrainz' do
        job.perform(artist.id)
        expect(artist.reload.country_code).to eq('GB')
      end

      it 'stores country_of_origin derived from the ISO code' do
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

    context 'when artist already has country_code' do
      let(:artist) { create(:artist, id_on_spotify: 'spotify_123', country_code: 'NL', country_of_origin: ['Netherlands']) }

      it 'does not overwrite country_code' do
        job.perform(artist.id)
        expect(artist.reload.country_code).to eq('NL')
      end

      it 'does not call MusicBrainz' do
        job.perform(artist.id)
        expect(MusicBrainz::ArtistCountryFinder).not_to have_received(:new)
      end

      it 'does not call Spotify' do
        job.perform(artist.id)
        expect(Spotify::ArtistFinder).not_to have_received(:new)
      end
    end

    context 'when MusicBrainz returns no country' do
      before do
        country_finder = instance_double(MusicBrainz::ArtistCountryFinder, call: nil)
        allow(MusicBrainz::ArtistCountryFinder).to receive(:new).and_return(country_finder)
      end

      it 'does not update country_code' do
        job.perform(artist.id)
        expect(artist.reload.country_code).to be_nil
      end

      it 'does not update country_of_origin' do
        job.perform(artist.id)
        expect(artist.reload.country_of_origin).to eq([])
      end

      it 'still records the check timestamp', :aggregate_failures do
        freeze_time = Time.current
        allow(Time).to receive(:current).and_return(freeze_time)

        job.perform(artist.id)

        expect(artist.reload.country_code).to be_nil
        expect(artist.country_of_origin_checked_at).to be_within(1.second).of(freeze_time)
      end
    end

    context 'when MusicBrainz returns an unknown ISO code' do
      before do
        country_finder = instance_double(MusicBrainz::ArtistCountryFinder, call: 'ZZ')
        allow(MusicBrainz::ArtistCountryFinder).to receive(:new).and_return(country_finder)
      end

      it 'does not update country_code or country_of_origin', :aggregate_failures do
        job.perform(artist.id)
        artist.reload
        expect(artist.country_code).to be_nil
        expect(artist.country_of_origin).to eq([])
      end
    end

    context 'when artist has no Spotify ID' do
      let(:artist) { create(:artist, id_on_spotify: nil, country_code: nil) }

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

    context 'when artist was checked recently and MusicBrainz had no country' do
      let(:artist) do
        create(:artist, id_on_spotify: 'spotify_123', country_code: nil, country_of_origin_checked_at: 2.days.ago)
      end

      it 'does not call MusicBrainz again' do
        job.perform(artist.id)
        expect(MusicBrainz::ArtistCountryFinder).not_to have_received(:new)
      end
    end

    context 'when artist was checked long ago and country is still missing' do
      let(:artist) do
        create(:artist, id_on_spotify: 'spotify_123', country_code: nil,
                        country_of_origin_checked_at: (described_class::RECHECK_AFTER + 1.day).ago)
      end

      it 'rechecks MusicBrainz' do
        job.perform(artist.id)
        expect(artist.reload.country_code).to eq('GB')
      end
    end
  end

  describe '.enqueue_all' do
    let!(:artist_without_country) { create(:artist, country_code: nil) }
    let!(:artist_with_country) { create(:artist, country_code: 'NL', country_of_origin: ['Netherlands']) }
    let!(:artist_recently_checked) do
      create(:artist, country_code: nil, country_of_origin_checked_at: 1.day.ago)
    end
    let!(:artist_stale_check) do
      create(:artist, country_code: nil, country_of_origin_checked_at: (described_class::RECHECK_AFTER + 1.day).ago)
    end

    before do
      allow(described_class).to receive(:perform_in)
    end

    it 'enqueues jobs for artists without country_code' do
      described_class.enqueue_all
      expect(described_class).to have_received(:perform_in).with(
        anything, artist_without_country.id
      )
    end

    it 'does not enqueue jobs for artists with country_code' do
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
