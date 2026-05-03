# frozen_string_literal: true

require 'rails_helper'

describe Itunes::ArtistEnricher do
  subject(:enricher) { described_class.new(artist) }

  let(:artist) { create(:artist, name: 'Bruno Mars', id_on_itunes: nil) }

  describe '#enrich' do
    context 'when artist is blank' do
      subject(:enricher) { described_class.new(nil) }

      it 'returns nil' do
        expect(enricher.enrich).to be_nil
      end
    end

    context 'when artist already has id_on_itunes' do
      let(:artist) { create(:artist, name: 'Bruno Mars', id_on_itunes: '278873078') }

      before do
        allow(Itunes::ArtistFinder::Result).to receive(:new)
      end

      it 'does not fetch from iTunes' do
        enricher.enrich
        expect(Itunes::ArtistFinder::Result).not_to have_received(:new)
      end
    end

    context 'when iTunes returns a valid match' do
      let(:itunes_result) do
        instance_double(
          Itunes::ArtistFinder::Result,
          execute: {},
          valid_match?: true,
          id: '278873078',
          itunes_artist_url: 'https://music.apple.com/nl/artist/bruno-mars/278873078'
        )
      end

      before do
        allow(Itunes::ArtistFinder::Result).to receive(:new).and_return(itunes_result)
      end

      it 'updates the artist with id_on_itunes and URL', :aggregate_failures do
        enricher.enrich
        artist.reload
        expect(artist.id_on_itunes).to eq('278873078')
        expect(artist.itunes_artist_url).to eq('https://music.apple.com/nl/artist/bruno-mars/278873078')
      end
    end

    context 'when iTunes returns no valid match' do
      let(:itunes_result) do
        instance_double(Itunes::ArtistFinder::Result, execute: nil, valid_match?: false)
      end

      before do
        allow(Itunes::ArtistFinder::Result).to receive(:new).and_return(itunes_result)
      end

      it 'does not update the artist' do
        enricher.enrich
        expect(artist.reload.id_on_itunes).to be_nil
      end
    end
  end
end
