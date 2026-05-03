# frozen_string_literal: true

require 'rails_helper'

describe Tidal::SongEnricher do
  subject(:enricher) { described_class.new(song) }

  let(:artist) { create(:artist, name: 'Ed Sheeran') }
  let(:song) { create(:song, title: 'Shape of You', isrcs: ['GBAHS1600786'], id_on_tidal: nil) }

  before do
    song.artists << artist
  end

  describe '#enrich' do
    context 'when song is blank' do
      subject(:enricher) { described_class.new(nil) }

      it 'returns nil' do
        expect(enricher.enrich).to be_nil
      end
    end

    context 'when song already has id_on_tidal' do
      let(:song) { create(:song, title: 'Shape of You', id_on_tidal: '12345') }

      before do
        allow(Tidal::TrackFinder::Result).to receive(:new)
      end

      it 'does not fetch from Tidal' do
        enricher.enrich
        expect(Tidal::TrackFinder::Result).not_to have_received(:new)
      end
    end

    context 'when Tidal returns a valid match' do
      let(:tidal_result) do
        instance_double(
          Tidal::TrackFinder::Result,
          execute: {},
          valid_match?: true,
          id: '12345',
          tidal_song_url: 'https://tidal.com/browse/track/12345',
          tidal_artwork_url: 'https://resources.tidal.com/images/large.jpg'
        )
      end

      before do
        allow(Tidal::TrackFinder::Result).to receive(:new).and_return(tidal_result)
      end

      it 'updates the song with id_on_tidal', :aggregate_failures do
        enricher.enrich
        song.reload
        expect(song.id_on_tidal).to eq('12345')
        expect(song.tidal_song_url).to eq('https://tidal.com/browse/track/12345')
        expect(song.tidal_artwork_url).to eq('https://resources.tidal.com/images/large.jpg')
      end
    end

    context 'when Tidal returns no valid match' do
      let(:tidal_result) do
        instance_double(Tidal::TrackFinder::Result, execute: nil, valid_match?: false)
      end

      before do
        allow(Tidal::TrackFinder::Result).to receive(:new).and_return(tidal_result)
      end

      it 'does not update the song' do
        enricher.enrich
        expect(song.reload.id_on_tidal).to be_nil
      end
    end
  end
end
