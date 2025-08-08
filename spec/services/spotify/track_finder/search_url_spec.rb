# frozen_string_literal: true

require 'rails_helper'

describe Spotify::TrackFinder::SearchUrl do
  describe '#generate' do
    context 'when spotify_url is present' do
      let(:search_url) do
        described_class.new(
          title: 'Test Song',
          artists: 'Test Artist',
          spotify_url: 'spotify:search:test+query'
        )
      end

      it 'returns a URI with the spotify_url search query' do
        uri = search_url.generate
        expect(uri.to_s).to eq('https://api.spotify.com/v1/search?q=test+query&type=track')
      end
    end

    context 'when spotify_url is not present' do
      let(:search_url) do
        described_class.new(
          title: 'Test Song',
          artists: 'Test Artist',
          spotify_url: nil
        )
      end

      it 'returns a URI with the title and artist as query' do
        uri = search_url.generate
        expect(uri.to_s).to eq('https://api.spotify.com/v1/search?q=Test%20Song%20artist%3Atest%20artist&type=track')
      end
    end

    context 'when artists contains multiple artists' do
      let(:search_url) do
        described_class.new(
          title: 'Test Song',
          artists: 'Artist1 & Artist2',
          spotify_url: nil
        )
      end

      it 'formats multiple artists correctly in the query' do
        uri = search_url.generate
        expect(uri.to_s).to include('artist%3Aartist1%20artist2')
      end
    end
  end
end
