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

    context 'when plain mode is requested' do
      let(:search_url) do
        described_class.new(
          title: 'Ik Bel Je Zo Maar Even Op',
          artists: 'Gordon',
          spotify_url: nil
        )
      end

      it 'omits the artist: field filter' do
        uri = search_url.generate(plain: true)
        expect(uri.to_s).not_to include('artist%3A')
      end

      it 'concatenates artist and title in the query' do
        uri = search_url.generate(plain: true)
        expect(uri.to_s).to eq('https://api.spotify.com/v1/search?q=gordon%20Ik%20Bel%20Je%20Zo%20Maar%20Even%20Op&type=track')
      end
    end

    context 'when plain mode is requested and a spotify_url is given' do
      let(:search_url) do
        described_class.new(
          title: 'Test Song',
          artists: 'Test Artist',
          spotify_url: 'spotify:search:test+query'
        )
      end

      it 'still honors the explicit spotify_url' do
        uri = search_url.generate(plain: true)
        expect(uri.to_s).to eq('https://api.spotify.com/v1/search?q=test+query&type=track')
      end
    end
  end
end
