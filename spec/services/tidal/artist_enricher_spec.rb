# frozen_string_literal: true

require 'rails_helper'

describe Tidal::ArtistEnricher do
  subject(:enricher) { described_class.new(artist) }

  let(:artist) { create(:artist, name: 'Bruno Mars', id_on_tidal: nil) }

  describe '#enrich' do
    context 'when artist is blank' do
      subject(:enricher) { described_class.new(nil) }

      it 'returns nil' do
        expect(enricher.enrich).to be_nil
      end
    end

    context 'when artist already has id_on_tidal' do
      let(:artist) { create(:artist, name: 'Bruno Mars', id_on_tidal: '12345') }

      before do
        allow(Tidal::ArtistFinder::Result).to receive(:new)
      end

      it 'does not fetch from Tidal' do
        enricher.enrich
        expect(Tidal::ArtistFinder::Result).not_to have_received(:new)
      end
    end

    context 'when Tidal returns a valid match' do
      let(:tidal_result) do
        instance_double(
          Tidal::ArtistFinder::Result,
          execute: {},
          valid_match?: true,
          id: '3658521',
          tidal_artist_url: 'https://tidal.com/browse/artist/3658521'
        )
      end

      before do
        allow(Tidal::ArtistFinder::Result).to receive(:new).and_return(tidal_result)
      end

      it 'updates the artist with id_on_tidal and the URL', :aggregate_failures do
        enricher.enrich
        artist.reload
        expect(artist.id_on_tidal).to eq('3658521')
        expect(artist.tidal_artist_url).to eq('https://tidal.com/browse/artist/3658521')
      end
    end

    context 'when Tidal returns no valid match' do
      let(:tidal_result) do
        instance_double(Tidal::ArtistFinder::Result, execute: nil, valid_match?: false)
      end

      before do
        allow(Tidal::ArtistFinder::Result).to receive(:new).and_return(tidal_result)
      end

      it 'does not update the artist' do
        enricher.enrich
        expect(artist.reload.id_on_tidal).to be_nil
      end
    end
  end
end
