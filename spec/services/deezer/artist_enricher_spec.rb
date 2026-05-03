# frozen_string_literal: true

require 'rails_helper'

describe Deezer::ArtistEnricher do
  subject(:enricher) { described_class.new(artist) }

  let(:artist) { create(:artist, name: 'Bruno Mars', id_on_deezer: nil) }

  describe '#enrich' do
    context 'when artist is blank' do
      subject(:enricher) { described_class.new(nil) }

      it 'returns nil' do
        expect(enricher.enrich).to be_nil
      end
    end

    context 'when artist already has id_on_deezer' do
      let(:artist) { create(:artist, name: 'Bruno Mars', id_on_deezer: '429675') }

      before do
        allow(Deezer::ArtistFinder::Result).to receive(:new)
      end

      it 'does not fetch from Deezer' do
        enricher.enrich
        expect(Deezer::ArtistFinder::Result).not_to have_received(:new)
      end
    end

    context 'when Deezer returns a valid match' do
      let(:deezer_result) do
        instance_double(
          Deezer::ArtistFinder::Result,
          execute: {},
          valid_match?: true,
          id: '429675',
          deezer_artist_url: 'https://www.deezer.com/artist/429675',
          deezer_artwork_url: 'https://cdn.example.com/xl.jpg'
        )
      end

      before do
        allow(Deezer::ArtistFinder::Result).to receive(:new).and_return(deezer_result)
      end

      it 'updates the artist with id_on_deezer, URL, and artwork', :aggregate_failures do
        enricher.enrich
        artist.reload
        expect(artist.id_on_deezer).to eq('429675')
        expect(artist.deezer_artist_url).to eq('https://www.deezer.com/artist/429675')
        expect(artist.deezer_artwork_url).to eq('https://cdn.example.com/xl.jpg')
      end
    end

    context 'when Deezer returns no valid match' do
      let(:deezer_result) do
        instance_double(Deezer::ArtistFinder::Result, execute: nil, valid_match?: false)
      end

      before do
        allow(Deezer::ArtistFinder::Result).to receive(:new).and_return(deezer_result)
      end

      it 'does not update the artist' do
        enricher.enrich
        expect(artist.reload.id_on_deezer).to be_nil
      end
    end
  end
end
