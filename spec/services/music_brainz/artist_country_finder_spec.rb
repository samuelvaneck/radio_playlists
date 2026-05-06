# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MusicBrainz::ArtistCountryFinder, type: :service do
  let(:artist) { create(:artist, name: 'Adele') }
  let(:mbid) { 'cc2c9c3c-b7bc-4b8b-84d8-4fbd8779e493' }
  let(:finder) { described_class.new(artist) }

  before { allow(finder).to receive(:sleep) }

  describe '#call' do
    context 'when artist already has id_on_musicbrainz and lookup returns a country code' do
      before do
        artist.update!(id_on_musicbrainz: mbid)
        stub_request(:get, %r{musicbrainz.org/ws/2/artist/#{mbid}})
          .to_return(status: 200, body: { 'id' => mbid, 'country' => 'GB' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns the ISO 3166-1 alpha-2 code' do
        expect(finder.()).to eq('GB')
      end
    end

    context 'when the lookup omits country but includes area iso codes' do
      before do
        artist.update!(id_on_musicbrainz: mbid)
        stub_request(:get, %r{musicbrainz.org/ws/2/artist/#{mbid}})
          .to_return(status: 200,
                     body: { 'id' => mbid, 'country' => nil, 'area' => { 'iso-3166-1-codes' => ['NL'] } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'falls back to the area code' do
        expect(finder.()).to eq('NL')
      end
    end

    context 'when the artist has no MBID and the search top match passes validation' do
      before do
        stub_request(:get, %r{musicbrainz.org/ws/2/artist\?}).to_return(
          status: 200,
          body: { 'artists' => [{ 'id' => mbid, 'name' => 'Adele', 'score' => 100 }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        stub_request(:get, %r{musicbrainz.org/ws/2/artist/#{mbid}}).to_return(
          status: 200, body: { 'id' => mbid, 'country' => 'GB' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'persists the discovered MBID and returns the country code', :aggregate_failures do
        result = finder.()
        expect(result).to eq('GB')
        expect(artist.reload.id_on_musicbrainz).to eq(mbid)
      end
    end

    context 'when the search top match score is below threshold' do
      before do
        stub_request(:get, %r{musicbrainz.org/ws/2/artist\?}).to_return(
          status: 200,
          body: { 'artists' => [{ 'id' => mbid, 'name' => 'Adele', 'score' => 80 }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'returns nil', :aggregate_failures do
        expect(finder.()).to be_nil
        expect(artist.reload.id_on_musicbrainz).to be_nil
      end
    end

    context 'when the lookup returns no country at all' do
      before do
        artist.update!(id_on_musicbrainz: mbid)
        stub_request(:get, %r{musicbrainz.org/ws/2/artist/#{mbid}})
          .to_return(status: 200, body: { 'id' => mbid, 'country' => nil }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns nil' do
        expect(finder.()).to be_nil
      end
    end

    context 'when the lookup endpoint returns an HTTP error' do
      before do
        artist.update!(id_on_musicbrainz: mbid)
        stub_request(:get, %r{musicbrainz.org/ws/2/artist/#{mbid}}).to_return(status: 503)
      end

      it 'returns nil' do
        expect(finder.()).to be_nil
      end
    end
  end
end
