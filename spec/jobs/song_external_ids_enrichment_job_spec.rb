# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SongExternalIdsEnrichmentJob do
  describe '#perform' do
    let(:job) { described_class.new }

    context 'when song exists', :use_vcr do
      let(:song) { create(:song, title: 'Test Song', isrc: 'USRC12345678', id_on_deezer: nil, id_on_itunes: nil) }

      before do
        allow(Deezer::SongEnricher).to receive(:new).and_return(instance_double(Deezer::SongEnricher, enrich: true))
        allow(Itunes::SongEnricher).to receive(:new).and_return(instance_double(Itunes::SongEnricher, enrich: true))
      end

      it 'enriches the song with external services', :aggregate_failures do
        job.perform(song.id)

        expect(Deezer::SongEnricher).to have_received(:new).with(song)
        expect(Itunes::SongEnricher).to have_received(:new).with(song)
      end
    end

    context 'when song does not exist' do
      it 'does not raise an error' do
        expect do
          job.perform(999_999)
        end.not_to raise_error
      end
    end

    context 'when song is missing deezer id', :use_vcr do
      let(:song) { create(:song, title: 'Test Song', isrc: 'USRC12345678', id_on_deezer: nil, id_on_itunes: '123') }

      before do
        allow(Deezer::SongEnricher).to receive(:new).and_return(instance_double(Deezer::SongEnricher, enrich: true))
      end

      it 'calls Deezer enricher' do
        job.perform(song.id)

        expect(Deezer::SongEnricher).to have_received(:new).with(song)
      end
    end

    context 'when song is missing itunes id', :use_vcr do
      let(:song) { create(:song, title: 'Test Song', id_on_deezer: '456', id_on_itunes: nil) }

      before do
        allow(Itunes::SongEnricher).to receive(:new).and_return(instance_double(Itunes::SongEnricher, enrich: true))
      end

      it 'calls iTunes enricher' do
        job.perform(song.id)

        expect(Itunes::SongEnricher).to have_received(:new).with(song)
      end
    end

    context 'when song already has all external ids' do
      let(:song) { create(:song, title: 'Test Song', id_on_deezer: '123456', id_on_itunes: '789012', isrcs: %w[USRC12345678]) }

      it 'does not call enrichment services', :aggregate_failures do
        allow(Deezer::SongEnricher).to receive(:new)
        allow(Itunes::SongEnricher).to receive(:new)
        allow(MusicBrainz::SongEnricher).to receive(:new)

        job.perform(song.id)

        expect(Deezer::SongEnricher).not_to have_received(:new)
        expect(Itunes::SongEnricher).not_to have_received(:new)
        expect(MusicBrainz::SongEnricher).not_to have_received(:new)
      end
    end
  end

  describe '.enqueue_all' do
    let!(:song_missing_deezer) { create(:song, id_on_deezer: nil, id_on_itunes: '123') }
    let!(:song_missing_itunes) { create(:song, id_on_deezer: '456', id_on_itunes: nil) }
    let!(:song_missing_both) { create(:song, id_on_deezer: nil, id_on_itunes: nil) }
    let!(:song_missing_isrcs) { create(:song, id_on_deezer: '111', id_on_itunes: '222', isrc: 'USRC12345678', isrcs: []) }
    let!(:song_complete) { create(:song, id_on_deezer: '789', id_on_itunes: '012', isrcs: %w[USRC12345678]) }

    it 'enqueues jobs for songs missing external IDs', :aggregate_failures do
      allow(described_class).to receive(:perform_async)

      described_class.enqueue_all

      expect(described_class).to have_received(:perform_async).with(song_missing_deezer.id)
      expect(described_class).to have_received(:perform_async).with(song_missing_itunes.id)
      expect(described_class).to have_received(:perform_async).with(song_missing_both.id)
      expect(described_class).to have_received(:perform_async).with(song_missing_isrcs.id)
      expect(described_class).not_to have_received(:perform_async).with(song_complete.id)
    end
  end
end
