# frozen_string_literal: true

require 'rails_helper'

describe Tidal::ArtistFinder::Result do
  subject(:result) { described_class.new(name: name) }

  let(:name) { 'Bruno Mars' }

  before do
    allow(Tidal::Token).to receive(:new).and_return(instance_double(Tidal::Token, token: 'fake_token'))
  end

  def search_response(ranked_ids:, included:)
    {
      'data' => {
        'id' => 'q', 'type' => 'searchResults',
        'attributes' => { 'trackingId' => 'abc' },
        'relationships' => { 'artists' => { 'data' => ranked_ids.map { |id| { 'id' => id, 'type' => 'artists' } } } }
      },
      'included' => included
    }
  end

  def stub_search(body)
    stub_request(:get, %r{openapi\.tidal\.com/v2/searchResults}).to_return(
      status: 200,
      body: body.to_json,
      headers: { 'Content-Type' => 'application/vnd.api+json' }
    )
  end

  def artist_resource(id:, name:, popularity: 0.5)
    {
      'id' => id, 'type' => 'artists',
      'attributes' => { 'name' => name, 'popularity' => popularity }
    }
  end

  describe '#execute' do
    context 'when the top-ranked artist matches the search name' do
      let(:included) do
        [
          artist_resource(id: '11002332', name: 'Bruno Mari', popularity: 0.05),
          artist_resource(id: '3658521', name: 'Bruno Mars', popularity: 0.97),
          artist_resource(id: '1565', name: 'Maroon 5', popularity: 0.92)
        ]
      end

      before do
        stub_search(search_response(ranked_ids: %w[3658521 11002332 1565], included: included))
        result.execute
      end

      it 'picks the top-ranked artist whose name passes the threshold' do
        expect(result.id).to eq('3658521')
      end

      it 'exposes the matched artist name' do
        expect(result.name).to eq('Bruno Mars')
      end

      it 'builds the canonical artist URL from the id' do
        expect(result.tidal_artist_url).to eq('https://tidal.com/browse/artist/3658521')
      end

      it 'is a valid match' do
        expect(result.valid_match?).to be true
      end
    end

    context 'when the top-ranked artist fails the threshold but a later one passes' do
      let(:included) do
        [
          artist_resource(id: '1565', name: 'Maroon 5', popularity: 0.92),
          artist_resource(id: '3658521', name: 'Bruno Mars', popularity: 0.97)
        ]
      end

      before do
        stub_search(search_response(ranked_ids: %w[1565 3658521], included: included))
        result.execute
      end

      it 'walks past the low-similarity top result and picks the next valid one' do
        expect(result.id).to eq('3658521')
      end
    end

    context 'when no candidate passes the name threshold' do
      let(:included) do
        [
          artist_resource(id: 'wrong-1', name: 'Completely Different', popularity: 0.5),
          artist_resource(id: 'wrong-2', name: 'Another Mismatch', popularity: 0.3)
        ]
      end

      before do
        stub_search(search_response(ranked_ids: %w[wrong-1 wrong-2], included: included))
        result.execute
      end

      it 'returns nil for artist' do
        expect(result.artist).to be_nil
      end

      it 'is not a valid match' do
        expect(result.valid_match?).to be false
      end
    end

    context 'when search returns no artists' do
      before do
        stub_search('data' => { 'id' => 'q', 'type' => 'searchResults', 'attributes' => {} }, 'included' => [])
        result.execute
      end

      it 'returns nil for id' do
        expect(result.id).to be_nil
      end
    end
  end
end
