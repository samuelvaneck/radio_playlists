# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArtistExternalIdsEnrichmentJob do
  describe '#perform' do
    let(:job) { described_class.new }

    context 'when artist exists and is missing IDs' do
      let(:artist) { create(:artist, name: 'Bruno Mars', id_on_tidal: nil, id_on_deezer: nil, id_on_itunes: nil) }

      before do
        allow(Tidal::ArtistEnricher).to receive(:new).and_return(instance_double(Tidal::ArtistEnricher, enrich: true))
        allow(Deezer::ArtistEnricher).to receive(:new).and_return(instance_double(Deezer::ArtistEnricher, enrich: true))
        allow(Itunes::ArtistEnricher).to receive(:new).and_return(instance_double(Itunes::ArtistEnricher, enrich: true))
      end

      it 'calls all three enrichers', :aggregate_failures do
        job.perform(artist.id)

        expect(Tidal::ArtistEnricher).to have_received(:new).with(artist)
        expect(Deezer::ArtistEnricher).to have_received(:new).with(artist)
        expect(Itunes::ArtistEnricher).to have_received(:new).with(artist)
      end
    end

    context 'when artist already has every external ID' do
      let(:artist) do
        create(:artist, name: 'Bruno Mars', id_on_tidal: '3658521', id_on_deezer: '429675', id_on_itunes: '278873078')
      end

      before do
        allow(Tidal::ArtistEnricher).to receive(:new)
        allow(Deezer::ArtistEnricher).to receive(:new)
        allow(Itunes::ArtistEnricher).to receive(:new)
        job.perform(artist.id)
      end

      it 'does not call any enricher', :aggregate_failures do
        expect(Tidal::ArtistEnricher).not_to have_received(:new)
        expect(Deezer::ArtistEnricher).not_to have_received(:new)
        expect(Itunes::ArtistEnricher).not_to have_received(:new)
      end
    end

    context 'when artist does not exist' do
      it 'does not raise an error' do
        expect { job.perform(999_999) }.not_to raise_error
      end
    end
  end

  describe '.enqueue_all' do
    let!(:missing_tidal) { create(:artist, name: 'A', id_on_tidal: nil, id_on_deezer: '1', id_on_itunes: '2') }
    let!(:missing_deezer) { create(:artist, name: 'B', id_on_tidal: '1', id_on_deezer: nil, id_on_itunes: '2') }
    let!(:missing_itunes) { create(:artist, name: 'C', id_on_tidal: '1', id_on_deezer: '2', id_on_itunes: nil) }
    let!(:complete) { create(:artist, name: 'D', id_on_tidal: '1', id_on_deezer: '2', id_on_itunes: '3') }

    it 'enqueues only artists missing at least one ID', :aggregate_failures do
      allow(described_class).to receive(:perform_async)

      described_class.enqueue_all

      expect(described_class).to have_received(:perform_async).with(missing_tidal.id)
      expect(described_class).to have_received(:perform_async).with(missing_deezer.id)
      expect(described_class).to have_received(:perform_async).with(missing_itunes.id)
      expect(described_class).not_to have_received(:perform_async).with(complete.id)
    end
  end
end
