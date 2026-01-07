# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SongExternalIdsEnrichmentJob do
  describe '#perform' do
    let(:song) { create(:song, title: 'Test Song', isrc: 'USRC12345678') }
    let(:job) { described_class.new }

    context 'when song exists' do
      it 'calls enrich_with_external_services on the song' do
        allow(Song).to receive(:find_by).with(id: song.id).and_return(song)
        allow(song).to receive(:enrich_with_external_services)

        job.perform(song.id)

        expect(song).to have_received(:enrich_with_external_services)
      end
    end

    context 'when song does not exist' do
      it 'does not raise an error' do
        expect do
          job.perform(999_999)
        end.not_to raise_error
      end
    end

    context 'when song is missing deezer id' do
      let(:song) { create(:song, title: 'Test Song', isrc: 'USRC12345678', id_on_deezer: nil) }

      it 'calls enrich_with_deezer' do
        allow(Song).to receive(:find_by).with(id: song.id).and_return(song)
        allow(song).to receive(:enrich_with_deezer)
        allow(song).to receive(:enrich_with_itunes)

        job.perform(song.id)

        expect(song).to have_received(:enrich_with_deezer)
      end
    end

    context 'when song is missing itunes id' do
      let(:song) { create(:song, title: 'Test Song', id_on_itunes: nil) }

      it 'calls enrich_with_itunes' do
        allow(Song).to receive(:find_by).with(id: song.id).and_return(song)
        allow(song).to receive(:enrich_with_deezer)
        allow(song).to receive(:enrich_with_itunes)

        job.perform(song.id)

        expect(song).to have_received(:enrich_with_itunes)
      end
    end

    context 'when song already has both external ids' do
      let(:song) { create(:song, title: 'Test Song', id_on_deezer: '123456', id_on_itunes: '789012') }

      it 'does not call enrichment methods', :aggregate_failures do
        allow(Song).to receive(:find_by).with(id: song.id).and_return(song)
        allow(song).to receive(:enrich_with_deezer)
        allow(song).to receive(:enrich_with_itunes)

        job.perform(song.id)

        expect(song).not_to have_received(:enrich_with_deezer)
        expect(song).not_to have_received(:enrich_with_itunes)
      end
    end
  end

  describe '.enqueue_all' do
    let!(:song_missing_deezer) { create(:song, id_on_deezer: nil, id_on_itunes: '123') }
    let!(:song_missing_itunes) { create(:song, id_on_deezer: '456', id_on_itunes: nil) }
    let!(:song_missing_both) { create(:song, id_on_deezer: nil, id_on_itunes: nil) }
    let!(:song_complete) { create(:song, id_on_deezer: '789', id_on_itunes: '012') }

    it 'enqueues jobs for songs missing external IDs', :aggregate_failures do
      allow(described_class).to receive(:perform_async)

      described_class.enqueue_all

      expect(described_class).to have_received(:perform_async).with(song_missing_deezer.id)
      expect(described_class).to have_received(:perform_async).with(song_missing_itunes.id)
      expect(described_class).to have_received(:perform_async).with(song_missing_both.id)
      expect(described_class).not_to have_received(:perform_async).with(song_complete.id)
    end
  end
end
