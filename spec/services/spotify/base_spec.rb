# frozen_string_literal: true

require 'rails_helper'

describe Spotify::Base, type: :service do
  let(:args) { { artists: 'Artist Name', title: 'Song Title' } }
  let(:spotify_base) { described_class.new(args) }
  let(:url) { 'https://api.spotify.com/v1/some_endpoint' }
  let(:token) { 'test_token' }

  before do
    allow(spotify_base).to receive(:token).and_return(token)
  end

  describe '#make_request' do
    subject(:make_request) { spotify_base.make_request(url) }

    context 'when the request is successful' do
      let(:response_body) { { 'key' => 'value' } }

      before do
        stub_request(:get, url)
          .with(headers: { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' })
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns the response body' do
        expect(make_request).to eq(response_body)
      end
    end

    context 'when the request fails' do
      before do
        stub_request(:get, url).to_raise(Faraday::Error)
        allow(ExceptionNotifier).to receive(:notify_new_relic)
      end

      it 'notifies the error to New Relic' do
        make_request
        expect(ExceptionNotifier).to have_received(:notify_new_relic).once
      end

      it 'returns nil after 3 attempts' do
        expect(make_request).to be_nil
      end
    end
  end

  describe '#make_request_with_match' do
    let(:result) { spotify_base.make_request_with_match(url) }
    let(:tracks_response) do
      {
        'tracks' => {
          'items' => [
            { 'name' => 'Track 1', 'album' => { 'artists' => [{ 'name' => 'Artist 1' }] }, 'popularity' => 50 },
            { 'name' => 'Track 2', 'album' => { 'artists' => [{ 'name' => 'Artist 2' }] }, 'popularity' => 30 }
          ]
        }
      }
    end

    before do
      allow(spotify_base).to receive(:make_request).and_return(tracks_response)
    end

    it 'adds match, artist_distance and title_distance to the tracks' do
      expect(result['tracks']['items'].first).to include('match', 'artist_distance', 'title_distance')
    end
  end

  describe '#artist_distance' do
    context 'when artist names match exactly' do
      it 'returns 100' do
        expect(spotify_base.send(:artist_distance, 'Artist Name')).to eq(100)
      end
    end

    context 'when artist names are similar' do
      it 'returns a high score' do
        expect(spotify_base.send(:artist_distance, 'Artist Names')).to be > 80
      end
    end

    context 'when artist names are different' do
      it 'returns a low score' do
        expect(spotify_base.send(:artist_distance, 'Completely Different')).to be < 60
      end
    end
  end

  describe '#title_distance' do
    context 'when titles match exactly' do
      it 'returns 100' do
        expect(spotify_base.send(:title_distance, 'Song Title')).to eq(100)
      end
    end

    context 'when titles are similar' do
      it 'returns a high score' do
        expect(spotify_base.send(:title_distance, 'Song Titles')).to be > 80
      end
    end

    context 'when titles are different' do
      it 'returns a low score' do
        expect(spotify_base.send(:title_distance, 'Completely Different')).to be < 60
      end
    end
  end

  describe '#add_match' do
    let(:items) do
      [
        { 'name' => 'Song Title', 'album' => { 'artists' => [{ 'name' => 'Artist Name' }] }, 'popularity' => 50 }
      ]
    end

    context 'when both artist and title match well' do
      it 'calculates a high match score' do
        result = spotify_base.send(:add_match, items)
        # popularity (50) + (min(100, 100) * 2) = 250
        expect(result.first['match']).to eq(250)
      end
    end

    context 'when same artist but different song title' do
      let(:items) do
        [
          { 'name' => 'Completely Different Song', 'album' => { 'artists' => [{ 'name' => 'Artist Name' }] },
            'popularity' => 50 }
        ]
      end

      it 'calculates a low match score due to title mismatch' do
        result = spotify_base.send(:add_match, items)
        # The minimum of artist_distance (100) and title_distance (low) is used
        # So the match score should be low despite matching artist
        expect(result.first['match']).to be <= 150
        expect(result.first['artist_distance']).to eq(100)
        expect(result.first['title_distance']).to be < 60
      end
    end
  end
end
