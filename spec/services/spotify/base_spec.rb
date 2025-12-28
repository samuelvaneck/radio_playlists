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

    it 'adds match and title_distance to the tracks' do
      expect(result['tracks']['items'].first).to include('match', 'title_distance')
    end
  end
end
