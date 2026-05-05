# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wikipedia::UrlFinder, type: :service do
  let(:url_finder) { described_class.new }
  let(:artist) { create(:artist, name: 'Coldplay') }
  let(:mbid) { 'cc197bad-dc9c-440d-a5b5-d52ba2e14234' }

  before { allow(url_finder).to receive(:sleep) }

  describe '#find_for_artist' do
    context 'when artist has a MusicBrainz ID with a wikipedia url-relation' do
      let(:mb_response) do
        {
          'id' => mbid,
          'relations' => [
            { 'type' => 'wikidata', 'url' => { 'resource' => 'https://www.wikidata.org/wiki/Q45188' } },
            { 'type' => 'wikipedia', 'url' => { 'resource' => 'https://en.wikipedia.org/wiki/Coldplay' } }
          ]
        }
      end

      before do
        artist.update!(id_on_musicbrainz: mbid)
        stub_request(:get, %r{musicbrainz.org/ws/2/artist/#{mbid}})
          .to_return(status: 200, body: mb_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns the wikipedia URL from the MusicBrainz relation' do
        expect(url_finder.find_for_artist(artist)).to eq('https://en.wikipedia.org/wiki/Coldplay')
      end
    end

    context 'when MusicBrainz returns multiple wikipedia urls in different languages' do
      let(:mb_response) do
        {
          'id' => mbid,
          'relations' => [
            { 'type' => 'wikipedia', 'url' => { 'resource' => 'https://en.wikipedia.org/wiki/Coldplay' } },
            { 'type' => 'wikipedia', 'url' => { 'resource' => 'https://nl.wikipedia.org/wiki/Coldplay' } }
          ]
        }
      end

      before do
        artist.update!(id_on_musicbrainz: mbid)
        stub_request(:get, %r{musicbrainz.org/ws/2/artist/#{mbid}})
          .to_return(status: 200, body: mb_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'prefers the URL matching the configured language' do
        finder = described_class.new(language: 'nl')
        allow(finder).to receive(:sleep)
        expect(finder.find_for_artist(artist)).to eq('https://nl.wikipedia.org/wiki/Coldplay')
      end
    end

    context 'when artist has no MusicBrainz ID and OpenSearch returns a matching title' do
      before do
        stub_request(:get, %r{en.wikipedia.org/w/api.php}).to_return(
          status: 200,
          body: ['Coldplay musician', ['Coldplay'], [''], ['https://en.wikipedia.org/wiki/Coldplay']].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'returns the URL from the OpenSearch top result' do
        expect(url_finder.find_for_artist(artist)).to eq('https://en.wikipedia.org/wiki/Coldplay')
      end
    end

    context 'when artist has a MusicBrainz ID without wikipedia url-rels' do
      before do
        artist.update!(id_on_musicbrainz: mbid)
        stub_request(:get, %r{musicbrainz.org/ws/2/artist/#{mbid}}).to_return(
          status: 200,
          body: { 'id' => mbid, 'relations' => [] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        stub_request(:get, %r{en.wikipedia.org/w/api.php}).to_return(
          status: 200,
          body: ['Coldplay musician', ['Coldplay'], [''], ['https://en.wikipedia.org/wiki/Coldplay']].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'falls back to OpenSearch' do
        expect(url_finder.find_for_artist(artist)).to eq('https://en.wikipedia.org/wiki/Coldplay')
      end
    end

    context 'when OpenSearch returns a title that is not similar enough' do
      let(:artist) { create(:artist, name: 'Pink') }

      before do
        stub_request(:get, %r{en.wikipedia.org/w/api.php}).to_return(
          status: 200,
          body: ['Pink musician', ['Pink Floyd'], [''], ['https://en.wikipedia.org/wiki/Pink_Floyd']].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'rejects the result' do
        expect(url_finder.find_for_artist(artist)).to be_nil
      end
    end

    context 'when OpenSearch returns a title with a parenthetical disambiguation suffix' do
      let(:artist) { create(:artist, name: 'Taylor Swift') }

      before do
        stub_request(:get, %r{en.wikipedia.org/w/api.php}).to_return(
          status: 200,
          body: [
            'Taylor Swift musician',
            ['Taylor Swift (singer)'],
            [''],
            ['https://en.wikipedia.org/wiki/Taylor_Swift_(singer)']
          ].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'strips the suffix before comparing and accepts the match' do
        expect(url_finder.find_for_artist(artist)).to eq('https://en.wikipedia.org/wiki/Taylor_Swift_(singer)')
      end
    end

    context 'when artist is nil' do
      it 'returns nil' do
        expect(url_finder.find_for_artist(nil)).to be_nil
      end
    end

    context 'when the MusicBrainz request errors' do
      before do
        artist.update!(id_on_musicbrainz: mbid)
        stub_request(:get, %r{musicbrainz.org/ws/2/artist/#{mbid}}).to_return(status: 503, body: 'Service Unavailable')
        stub_request(:get, %r{en.wikipedia.org/w/api.php}).to_return(
          status: 200,
          body: ['Coldplay musician', ['Coldplay'], [''], ['https://en.wikipedia.org/wiki/Coldplay']].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'falls back to OpenSearch' do
        expect(url_finder.find_for_artist(artist)).to eq('https://en.wikipedia.org/wiki/Coldplay')
      end
    end
  end

  describe '#find_for_name' do
    context 'when a hint is provided' do
      before do
        stub_request(:get, %r{en.wikipedia.org/w/api.php}).with(query: hash_including(search: 'Coldplay band')).to_return(
          status: 200,
          body: ['Coldplay band', ['Coldplay'], [''], ['https://en.wikipedia.org/wiki/Coldplay']].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'appends the hint to the search query' do
        expect(url_finder.find_for_name('Coldplay', hint: 'band')).to eq('https://en.wikipedia.org/wiki/Coldplay')
      end
    end

    context 'when name is blank' do
      it 'returns nil' do
        expect(url_finder.find_for_name('')).to be_nil
      end
    end
  end
end
