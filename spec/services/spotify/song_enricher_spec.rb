# frozen_string_literal: true

require 'rails_helper'

describe Spotify::SongEnricher do # rubocop:disable Metrics/BlockLength
  subject(:enricher) { described_class.new(song, force: force) }

  let(:song) { create(:song, id_on_spotify: 'spotify_id_123', spotify_song_url: nil, isrcs: []) }
  let(:force) { false }

  describe '#enrich' do # rubocop:disable Metrics/BlockLength
    context 'when song is blank' do
      subject(:enricher) { described_class.new(nil) }

      it 'returns nil' do
        expect(enricher.enrich).to be_nil
      end
    end

    context 'when song already has spotify_song_url and force is false' do
      let(:song) { create(:song, id_on_spotify: 'spotify_id_123', spotify_song_url: 'https://open.spotify.com/track/abc') }

      it 'returns nil without fetching' do
        expect(enricher.enrich).to be_nil
      end
    end

    context 'when Spotify returns valid data' do
      let(:spotify_response) do
        {
          'id' => 'spotify_id_123',
          'external_urls' => { 'spotify' => 'https://open.spotify.com/track/spotify_id_123' },
          'album' => { 'images' => [{ 'url' => 'https://i.scdn.co/image/artwork' }] },
          'preview_url' => 'https://p.scdn.co/mp3-preview/abc',
          'external_ids' => { 'isrc' => 'USGB12345678' },
          'duration_ms' => 210_000,
          'popularity' => 75,
          'explicit' => true,
          'artists' => []
        }
      end

      before do
        allow(Spotify::TrackFinder::FindById).to receive(:new).and_return(
          instance_double(Spotify::TrackFinder::FindById, execute: spotify_response)
        )
      end

      it 'updates the song with popularity' do
        enricher.enrich
        expect(song.reload.popularity).to eq(75)
      end

      it 'updates the song with explicit flag' do
        enricher.enrich
        expect(song.reload.explicit).to be(true)
      end

      it 'updates the song with spotify_song_url' do
        enricher.enrich
        expect(song.reload.spotify_song_url).to eq('https://open.spotify.com/track/spotify_id_123')
      end

      it 'updates the song with duration_ms' do
        enricher.enrich
        expect(song.reload.duration_ms).to eq(210_000)
      end
    end

    context 'when popularity is 0' do
      let(:spotify_response) do
        {
          'id' => 'spotify_id_123',
          'external_urls' => { 'spotify' => 'https://open.spotify.com/track/spotify_id_123' },
          'album' => { 'images' => [{ 'url' => 'https://i.scdn.co/image/artwork' }] },
          'preview_url' => nil,
          'external_ids' => { 'isrc' => nil },
          'duration_ms' => nil,
          'popularity' => 0,
          'explicit' => false,
          'artists' => []
        }
      end

      before do
        allow(Spotify::TrackFinder::FindById).to receive(:new).and_return(
          instance_double(Spotify::TrackFinder::FindById, execute: spotify_response)
        )
      end

      it 'persists popularity of 0' do
        enricher.enrich
        expect(song.reload.popularity).to eq(0)
      end

      it 'persists explicit of false' do
        enricher.enrich
        expect(song.reload.explicit).to be(false)
      end
    end

    context 'when Spotify returns nil for popularity and explicit' do
      let(:spotify_response) do
        {
          'id' => 'spotify_id_123',
          'external_urls' => { 'spotify' => 'https://open.spotify.com/track/spotify_id_123' },
          'album' => { 'images' => [{ 'url' => 'https://i.scdn.co/image/artwork' }] },
          'preview_url' => nil,
          'external_ids' => {},
          'duration_ms' => nil,
          'popularity' => nil,
          'explicit' => nil,
          'artists' => []
        }
      end

      before do
        allow(Spotify::TrackFinder::FindById).to receive(:new).and_return(
          instance_double(Spotify::TrackFinder::FindById, execute: spotify_response)
        )
      end

      it 'does not update popularity' do
        enricher.enrich
        expect(song.reload.popularity).to be_nil
      end

      it 'does not update explicit' do
        enricher.enrich
        expect(song.reload.explicit).to be(false)
      end
    end
  end

  describe '#build_updates' do # rubocop:disable Metrics/BlockLength
    subject(:updates) { enricher.send(:build_updates, result) }

    let(:result) do
      OpenStruct.new(
        id: 'spotify_id_123',
        spotify_song_url: 'https://open.spotify.com/track/spotify_id_123',
        spotify_artwork_url: 'https://i.scdn.co/image/artwork',
        spotify_preview_url: 'https://p.scdn.co/mp3-preview/abc',
        isrc: 'USGB12345678',
        duration_ms: 210_000,
        popularity: 82,
        explicit: true
      )
    end

    it 'includes popularity in updates' do
      expect(updates[:popularity]).to eq(82)
    end

    it 'includes explicit in updates' do
      expect(updates[:explicit]).to be(true)
    end

    context 'when popularity is nil' do
      let(:result) do
        OpenStruct.new(
          id: 'spotify_id_123',
          spotify_song_url: 'https://open.spotify.com/track/spotify_id_123',
          spotify_artwork_url: nil,
          spotify_preview_url: nil,
          isrc: nil,
          duration_ms: nil,
          popularity: nil,
          explicit: nil
        )
      end

      it 'does not include popularity in updates' do
        expect(updates).not_to have_key(:popularity)
      end

      it 'does not include explicit in updates' do
        expect(updates).not_to have_key(:explicit)
      end
    end

    context 'when popularity is 0' do
      let(:result) do
        OpenStruct.new(
          id: nil,
          spotify_song_url: nil,
          spotify_artwork_url: nil,
          spotify_preview_url: nil,
          isrc: nil,
          duration_ms: nil,
          popularity: 0,
          explicit: false
        )
      end

      it 'includes popularity of 0 in updates' do
        expect(updates[:popularity]).to eq(0)
      end

      it 'includes explicit of false in updates' do
        expect(updates[:explicit]).to be(false)
      end
    end
  end
end
