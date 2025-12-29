# frozen_string_literal: true

require 'rails_helper'

describe SongExternalIdsEnrichmentJob, type: :job do
  describe '#perform' do
    subject(:perform_job) { described_class.new.perform(song_id) }

    context 'when the song exists' do
      let(:song) { create(:song) }
      let(:song_id) { song.id }

      before do
        allow(Song).to receive(:find_by).with(id: song_id).and_return(song)
        allow(song).to receive(:enrich_with_external_services)
      end

      it 'calls enrich_with_external_services on the song' do
        perform_job

        expect(song).to have_received(:enrich_with_external_services)
      end
    end

    context 'when the song does not exist' do
      let(:song_id) { -1 }

      it 'returns early without error' do
        expect { perform_job }.not_to raise_error
      end
    end

    context 'when song_id is nil' do
      let(:song_id) { nil }

      it 'returns early without error' do
        expect { perform_job }.not_to raise_error
      end
    end
  end

  describe '.enqueue_all' do
    let!(:song_missing_deezer) { create(:song, id_on_deezer: nil, id_on_itunes: '123') }
    let!(:song_missing_itunes) { create(:song, id_on_deezer: '456', id_on_itunes: nil) }
    let!(:song_missing_both) { create(:song, id_on_deezer: nil, id_on_itunes: nil) }
    let!(:song_with_both) { create(:song, id_on_deezer: '789', id_on_itunes: '012') }

    before do
      allow(described_class).to receive(:perform_async)
    end

    it 'enqueues job for song missing deezer id' do
      described_class.enqueue_all

      expect(described_class).to have_received(:perform_async).with(song_missing_deezer.id)
    end

    it 'enqueues job for song missing itunes id' do
      described_class.enqueue_all

      expect(described_class).to have_received(:perform_async).with(song_missing_itunes.id)
    end

    it 'enqueues job for song missing both ids' do
      described_class.enqueue_all

      expect(described_class).to have_received(:perform_async).with(song_missing_both.id)
    end

    it 'does not enqueue job for song with both ids present' do
      described_class.enqueue_all

      expect(described_class).not_to have_received(:perform_async).with(song_with_both.id)
    end
  end
end
