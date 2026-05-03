# frozen_string_literal: true

require 'rails_helper'

describe Itunes::ArtistFinder::Result do
  subject(:result) { described_class.new(name: name) }

  let(:name) { 'Bruno Mars' }

  def itunes_response(artists)
    { 'results' => artists }
  end

  def stub_search(body)
    stub_request(:get, %r{itunes\.apple\.com/search}).to_return(
      status: 200,
      body: body.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  def artist_payload(artist_id:, artist_name:, artist_link_url: nil)
    {
      'wrapperType' => 'artist',
      'artistType' => 'Artist',
      'artistId' => artist_id,
      'artistName' => artist_name,
      'artistLinkUrl' => artist_link_url || "https://music.apple.com/nl/artist/#{artist_id}"
    }
  end

  describe '#execute' do
    context 'when the first result matches the search name' do
      let(:artists) do
        [
          artist_payload(artist_id: 278_873_078, artist_name: 'Bruno Mars'),
          artist_payload(artist_id: 1_556_097_160, artist_name: 'Silk Sonic'),
          artist_payload(artist_id: 2_307_416, artist_name: 'Thirty Seconds to Mars')
        ]
      end

      before do
        stub_search(itunes_response(artists))
        result.execute
      end

      it 'picks the exact-name match' do
        expect(result.id).to eq('278873078')
      end

      it 'exposes the artist URL' do
        expect(result.itunes_artist_url).to eq('https://music.apple.com/nl/artist/278873078')
      end

      it 'is a valid match' do
        expect(result.valid_match?).to be true
      end
    end

    context 'when no candidate passes the threshold' do
      let(:artists) do
        [
          artist_payload(artist_id: 1, artist_name: 'Silk Sonic'),
          artist_payload(artist_id: 2, artist_name: 'Thirty Seconds to Mars')
        ]
      end

      before do
        stub_search(itunes_response(artists))
        result.execute
      end

      it 'returns nil' do
        expect(result.artist).to be_nil
      end
    end

    context 'when iTunes returns no results' do
      before do
        stub_search('results' => [])
        result.execute
      end

      it 'returns nil' do
        expect(result.artist).to be_nil
      end
    end
  end
end
