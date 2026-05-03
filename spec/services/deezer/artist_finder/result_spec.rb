# frozen_string_literal: true

require 'rails_helper'

describe Deezer::ArtistFinder::Result do
  subject(:result) { described_class.new(name: name) }

  let(:name) { 'Bruno Mars' }

  def deezer_response(artists)
    { 'data' => artists }
  end

  def stub_search(body)
    stub_request(:get, %r{api\.deezer\.com/search/artist}).to_return(
      status: 200,
      body: body.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  def artist_payload(id:, name:, link: nil, picture_xl: nil)
    {
      'id' => id,
      'name' => name,
      'link' => link || "https://www.deezer.com/artist/#{id}",
      'picture_xl' => picture_xl || "https://cdn.example.com/#{id}/xl.jpg"
    }
  end

  describe '#execute' do
    context 'when the first result matches the search name' do
      let(:artists) do
        [
          artist_payload(id: 429_675, name: 'Bruno Mars'),
          artist_payload(id: 372_058_021, name: 'Bruno Mars & Rose'),
          artist_payload(id: 1_445_229, name: 'Bruno Mars Cover Band')
        ]
      end

      before do
        stub_search(deezer_response(artists))
        result.execute
      end

      it 'picks the exact-name match' do
        expect(result.id).to eq('429675')
      end

      it 'exposes the artist URL' do
        expect(result.deezer_artist_url).to eq('https://www.deezer.com/artist/429675')
      end

      it 'exposes the artwork URL' do
        expect(result.deezer_artwork_url).to eq('https://cdn.example.com/429675/xl.jpg')
      end

      it 'is a valid match' do
        expect(result.valid_match?).to be true
      end
    end

    context 'when the first result fails the threshold but a later one passes' do
      let(:artists) do
        [
          artist_payload(id: 1, name: 'Completely Different'),
          artist_payload(id: 429_675, name: 'Bruno Mars')
        ]
      end

      before do
        stub_search(deezer_response(artists))
        result.execute
      end

      it 'falls back to the next valid candidate' do
        expect(result.id).to eq('429675')
      end
    end

    context 'when no candidate passes the threshold' do
      let(:artists) do
        [artist_payload(id: 1, name: 'Completely Different')]
      end

      before do
        stub_search(deezer_response(artists))
        result.execute
      end

      it 'returns nil' do
        expect(result.artist).to be_nil
      end
    end

    context 'when Deezer returns an error response' do
      before do
        stub_search('error' => { 'type' => 'OAuthException' })
        result.execute
      end

      it 'returns nil' do
        expect(result.artist).to be_nil
      end
    end
  end
end
