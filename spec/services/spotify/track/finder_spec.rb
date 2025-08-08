# frozen_string_literal: true

require 'rails_helper'

describe Spotify::Track::Finder, :use_vcr do
  subject(:finder) { described_class.new(artists:, title:, spotify_search_url:, spotify_track_id:) }

  let(:artists) { 'Ed Sheeran' }
  let(:title) { 'Celestial' }
  let(:spotify_search_url) { nil }
  let(:spotify_track_id) { nil }

  describe '#execute' do
    before do
      finder.execute
    end

    context 'when the track is found' do
      it 'returns the correct title' do
        expect(finder.title).to eq('Celestial')
      end

      it 'returns the correct artists' do
        expect(finder.artists.pluck('name')).to contain_exactly('Ed Sheeran')
      end

      it 'returns the correct Spotify id' do
        expect(finder.id).to eq('4zrKN5Sv8JS5mqnbVcsul7')
      end

      it 'returns the correct ISRC code' do
        expect(finder.isrc).to eq('GBAHS2201129')
      end
    end

    context 'when the track is not found' do
      let(:title) { 'Nonexistent Track' }
      let(:artists) { 'Unknown Artist' }

      it 'returns the correct title' do
        expect(finder.title).to be_nil
      end

      it 'returns the correct artists' do
        expect(finder.artists).to be_nil
      end

      it 'returns the correct Spotify id' do
        expect(finder.id).to be_nil
      end

      it 'returns the correct ISRC code' do
        expect(finder.isrc).to be_nil
      end
    end

    context 'when given a Spotify track ID' do
      let(:spotify_track_id) { '4zrKN5Sv8JS5mqnbVcsul7' }

      before do
        allow(finder).to receive(:fetch_spotify_track).and_call_original
        finder.execute
      end

      it 'fetches the track by ID' do
        expect(finder).to have_received(:fetch_spotify_track)
      end

      it 'returns the correct title' do
        expect(finder.title).to eq('Celestial')
      end

      it 'returns the correct artists' do
        expect(finder.artists.pluck('name')).to contain_exactly('Ed Sheeran')
      end

      it 'returns the correct Spotify id' do
        expect(finder.id).to eq('4zrKN5Sv8JS5mqnbVcsul7')
      end

      it 'returns the correct ISRC code' do
        expect(finder.isrc).to eq('GBAHS2201129')
      end
    end

    context 'when given a Spotify search URL' do
      let(:spotify_search_url) { 'spotify:search:ed+sheeran+celestial' }

      before do
        finder.execute
      end

      it 'returns the correct title' do
        expect(finder.title).to eq('Celestial')
      end

      it 'returns the correct artists' do
        expect(finder.artists.pluck('name')).to contain_exactly('Ed Sheeran')
      end

      it 'returns the correct Spotify id' do
        expect(finder.id).to eq('4zrKN5Sv8JS5mqnbVcsul7')
      end

      it 'returns the correct ISRC code' do
        expect(finder.isrc).to eq('GBAHS2201129')
      end
    end
  end
end
