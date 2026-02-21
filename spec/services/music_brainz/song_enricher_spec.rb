# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MusicBrainz::SongEnricher, type: :service do
  let(:song) { create(:song, isrc: 'USRC12345678', isrcs: []) }
  let(:enricher) { described_class.new(song) }

  describe '#enrich' do
    context 'when song is blank' do
      let(:enricher) { described_class.new(nil) }

      it 'does not call IsrcsFinder' do
        allow(MusicBrainz::IsrcsFinder).to receive(:new)
        enricher.enrich
        expect(MusicBrainz::IsrcsFinder).not_to have_received(:new)
      end
    end

    context 'when song has no ISRC' do
      let(:song) { create(:song, isrc: nil, isrcs: []) }

      it 'does not call IsrcsFinder' do
        allow(MusicBrainz::IsrcsFinder).to receive(:new)
        enricher.enrich
        expect(MusicBrainz::IsrcsFinder).not_to have_received(:new)
      end
    end

    context 'when song already has ISRCs populated' do
      let(:song) { create(:song, isrc: 'USRC12345678', isrcs: ['USRC12345678', 'GBABC1234567']) }

      it 'does not call IsrcsFinder' do
        allow(MusicBrainz::IsrcsFinder).to receive(:new)
        enricher.enrich
        expect(MusicBrainz::IsrcsFinder).not_to have_received(:new)
      end
    end

    context 'when MusicBrainz returns ISRCs' do
      let(:isrcs) { %w[USRC12345678 GBABC1234567 NLA5E2300100] }

      before do
        finder = instance_double(MusicBrainz::IsrcsFinder, find: isrcs)
        allow(MusicBrainz::IsrcsFinder).to receive(:new).with('USRC12345678').and_return(finder)
      end

      it 'updates the song isrcs' do
        enricher.enrich
        expect(song.reload.isrcs).to eq(isrcs)
      end
    end

    context 'when MusicBrainz returns empty results' do
      before do
        finder = instance_double(MusicBrainz::IsrcsFinder, find: [])
        allow(MusicBrainz::IsrcsFinder).to receive(:new).with('USRC12345678').and_return(finder)
      end

      it 'does not update the song' do
        expect { enricher.enrich }.not_to(change { song.reload.isrcs })
      end
    end
  end
end
