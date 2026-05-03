# frozen_string_literal: true

require 'rails_helper'

describe Tidal::TrackFinder::Result do
  subject(:result) { described_class.new(artists: artists, title: title, isrc: isrc) }

  let(:artists) { 'Ed Sheeran' }
  let(:title) { 'Shape of You' }
  let(:isrc) { nil }

  before do
    allow(Tidal::Token).to receive(:new).and_return(instance_double(Tidal::Token, token: 'fake_token'))
  end

  describe '#execute' do
    let(:tidal_track_response) do
      {
        'data' => [
          {
            'id' => '12345',
            'type' => 'tracks',
            'attributes' => {
              'title' => 'Shape of You',
              'isrc' => 'GBAHS1600786',
              'duration' => 'PT3M53S',
              'explicit' => false
            },
            'relationships' => {
              'artists' => { 'data' => [{ 'id' => '100', 'type' => 'artists' }] },
              'albums' => { 'data' => [{ 'id' => '200', 'type' => 'albums' }] }
            }
          }
        ],
        'included' => [
          { 'id' => '100', 'type' => 'artists', 'attributes' => { 'name' => 'Ed Sheeran' } },
          {
            'id' => '200', 'type' => 'albums',
            'attributes' => {
              'title' => 'Divide',
              'imageLinks' => [
                { 'href' => 'https://resources.tidal.com/images/small.jpg', 'meta' => { 'width' => 160, 'height' => 160 } },
                { 'href' => 'https://resources.tidal.com/images/large.jpg', 'meta' => { 'width' => 640, 'height' => 640 } }
              ]
            }
          }
        ]
      }
    end

    context 'when the track is found by ISRC' do
      let(:isrc) { 'GBAHS1600786' }

      before do
        stub_request(:get, %r{openapi\.tidal\.com/v2/tracks\?.*filter}).to_return(
          status: 200,
          body: tidal_track_response.to_json,
          headers: { 'Content-Type' => 'application/vnd.api+json' }
        )
        result.execute
      end

      it 'returns the correct title' do
        expect(result.title).to eq('Shape of You')
      end

      it 'returns the Tidal id' do
        expect(result.id).to eq('12345')
      end

      it 'returns the song URL' do
        expect(result.tidal_song_url).to eq('https://tidal.com/browse/track/12345')
      end

      it 'returns the largest artwork URL' do
        expect(result.tidal_artwork_url).to eq('https://resources.tidal.com/images/large.jpg')
      end

      it 'returns the ISRC' do
        expect(result.isrc).to eq('GBAHS1600786')
      end

      it 'returns duration in milliseconds' do
        expect(result.duration_ms).to eq(233_000)
      end

      it 'returns the artist name' do
        expect(result.artists.first['name']).to eq('Ed Sheeran')
      end
    end

    context 'when the track is found by query search' do
      let(:search_response) do
        {
          'data' => {
            'id' => 'shape of you',
            'type' => 'searchResults',
            'attributes' => { 'trackingId' => 'abc' },
            'relationships' => { 'tracks' => { 'data' => [{ 'id' => '12345', 'type' => 'tracks' }] } }
          },
          'included' => tidal_track_response['data'] + tidal_track_response['included']
        }
      end

      before do
        stub_request(:get, %r{openapi\.tidal\.com/v2/searchresults}).to_return(
          status: 200,
          body: search_response.to_json,
          headers: { 'Content-Type' => 'application/vnd.api+json' }
        )
        result.execute
      end

      it 'returns the correct title' do
        expect(result.title).to eq('Shape of You')
      end

      it 'returns the Tidal id' do
        expect(result.id).to eq('12345')
      end
    end

    context 'when the track is not found' do
      before do
        stub_request(:get, /openapi\.tidal\.com/).to_return(
          status: 200,
          body: { 'data' => [], 'included' => [] }.to_json,
          headers: { 'Content-Type' => 'application/vnd.api+json' }
        )
        result.execute
      end

      it 'returns nil for track' do
        expect(result.track).to be_nil
      end

      it 'returns nil for id' do
        expect(result.id).to be_nil
      end
    end
  end

  describe '#valid_match?' do
    context 'when both artist and title distances are high' do
      before do
        result.instance_variable_set(:@track, { 'artist_distance' => 85, 'title_distance' => 85 })
      end

      it 'returns true' do
        expect(result.valid_match?).to be true
      end
    end

    context 'when artist_distance is high but title_distance is low' do
      before do
        result.instance_variable_set(:@track, { 'artist_distance' => 85, 'title_distance' => 50 })
      end

      it 'returns false' do
        expect(result.valid_match?).to be false
      end
    end

    context 'when track is nil' do
      before do
        result.instance_variable_set(:@track, nil)
      end

      it 'returns false' do
        expect(result.valid_match?).to be false
      end
    end
  end
end
