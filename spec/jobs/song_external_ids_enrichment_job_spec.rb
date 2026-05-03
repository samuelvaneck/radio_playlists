# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SongExternalIdsEnrichmentJob do
  describe '#perform' do
    let(:job) { described_class.new }

    context 'when song exists', :use_vcr do
      let(:song) { create(:song, title: 'Test Song', isrcs: ['USRC12345678'], id_on_deezer: nil, id_on_itunes: nil) }

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
      let(:song) { create(:song, title: 'Test Song', isrcs: ['USRC12345678'], id_on_deezer: nil, id_on_itunes: '123') }

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
      let(:song) do
        create(:song, title: 'Test Song', id_on_deezer: '123456', id_on_itunes: '789012', id_on_tidal: 'tdl-001',
                      isrcs: %w[USRC12345678 GBABC1234567], duration_ms: 210_000)
      end

      it 'does not call enrichment services', :aggregate_failures do
        allow(Deezer::SongEnricher).to receive(:new)
        allow(Itunes::SongEnricher).to receive(:new)
        allow(Tidal::SongEnricher).to receive(:new)
        allow(MusicBrainz::SongEnricher).to receive(:new)

        job.perform(song.id)

        expect(Deezer::SongEnricher).not_to have_received(:new)
        expect(Itunes::SongEnricher).not_to have_received(:new)
        expect(Tidal::SongEnricher).not_to have_received(:new)
        expect(MusicBrainz::SongEnricher).not_to have_received(:new)
      end
    end
  end

  describe '.enqueue_all' do
    let!(:song_missing_deezer) { create(:song, id_on_deezer: nil, id_on_itunes: '123', id_on_tidal: 'tdl-1') }
    let!(:song_missing_itunes) { create(:song, id_on_deezer: '456', id_on_itunes: nil, id_on_tidal: 'tdl-2') }
    let!(:song_missing_both) { create(:song, id_on_deezer: nil, id_on_itunes: nil, id_on_tidal: 'tdl-3') }
    let!(:song_missing_isrcs) do
      create(:song, id_on_deezer: '111', id_on_itunes: '222', id_on_tidal: 'tdl-4', isrcs: ['USRC12345678'])
    end
    let!(:song_missing_tidal) { create(:song, id_on_deezer: '789', id_on_itunes: '012', id_on_tidal: nil) }
    let!(:song_complete) do
      create(:song, id_on_deezer: '789', id_on_itunes: '012', id_on_tidal: 'tdl-5', isrcs: %w[USRC12345678 GBABC1234567],
                    duration_ms: 210_000, release_date: Date.new(2023, 1, 1))
    end

    it 'enqueues jobs for songs missing external IDs', :aggregate_failures do
      allow(described_class).to receive(:perform_async)

      described_class.enqueue_all

      expect(described_class).to have_received(:perform_async).with(song_missing_deezer.id)
      expect(described_class).to have_received(:perform_async).with(song_missing_itunes.id)
      expect(described_class).to have_received(:perform_async).with(song_missing_both.id)
      expect(described_class).to have_received(:perform_async).with(song_missing_isrcs.id)
      expect(described_class).to have_received(:perform_async).with(song_missing_tidal.id)
      expect(described_class).not_to have_received(:perform_async).with(song_complete.id)
    end
  end
end
