# frozen_string_literal: true

require 'rails_helper'

describe Tidal::TrackFinder::Result do
  subject(:result) { described_class.new(artists: artists, title: title, isrc: isrc) }

  let(:artists) { 'Bruno Mars' }
  let(:title) { 'I Just Might' }
  let(:isrc) { nil }

  describe '#execute', :use_vcr do
    context 'when search returns the matching ISRC' do
      let(:isrc) { 'USAT22509144' }

      before { result.execute }

      it 'picks the track whose ISRC matches, ignoring more popular Bruno Mars hits' do
        expect(result.id).to eq('488282494')
      end

      it 'returns the matching ISRC' do
        expect(result.isrc).to eq('USAT22509144')
      end

      it 'returns the track title' do
        expect(result.title).to eq('I Just Might')
      end

      it 'returns the song URL' do
        expect(result.tidal_song_url).to eq('https://tidal.com/browse/track/488282494')
      end

      it 'returns duration_ms' do
        expect(result.duration_ms).to eq(213_000)
      end

      it 'returns the artists resolved from the included compound document' do
        expect(result.artists).to eq(['Bruno Mars'])
      end

      it 'leaves artwork empty (endpoint does not expose cover art inline)' do
        expect(result.tidal_artwork_url).to be_nil
      end
    end

    context 'when no ISRC is provided' do
      before { result.execute }

      it 'rejects more popular Bruno Mars songs via title distance' do
        expect(result.id).to eq('488282494')
      end
    end

    context 'when ISRC is provided but no candidate matches it' do
      let(:isrc) { 'NONEXISTENT' }

      before { result.execute }

      it 'falls back to the full pool and lets title distance pick the right track' do
        expect(result.id).to eq('488282494')
      end
    end

    context 'when no candidate passes the title threshold' do
      let(:title) { 'asdfqwerzxcv1234' }

      before { result.execute }

      it 'returns nil for track' do
        expect(result.track).to be_nil
      end
    end

    context 'when search returns no tracks' do
      let(:artists) { 'qzxqzxqzxnonexistentartistxxx' }
      let(:title) { 'noresult' }

      before { result.execute }

      it 'returns nil for track' do
        expect(result.track).to be_nil
      end

      it 'returns nil for id' do
        expect(result.id).to be_nil
      end
    end

    context 'when search returns a title-matching track by a different artist' do
      subject(:result) { described_class.new(artists: 'Gordon', title: 'Ik Bel Je Zomaar Even Op') }

      before { result.execute }

      it 'rejects the wrong-artist track and exposes no Tidal id' do
        expect(result.id).to be_nil
      end

      it 'is not a valid match' do
        expect(result.valid_match?).to be false
      end
    end
  end

  describe '#valid_match?' do
    context 'when both title and artist distances are above the threshold' do
      before do
        result.instance_variable_set(:@track, { 'title_distance' => 85, 'artist_distance' => 90 })
      end

      it 'returns true' do
        expect(result.valid_match?).to be true
      end
    end

    context 'when title_distance is below the threshold' do
      before do
        result.instance_variable_set(:@track, { 'title_distance' => 50, 'artist_distance' => 90 })
      end

      it 'returns false' do
        expect(result.valid_match?).to be false
      end
    end

    context 'when artist_distance is below the threshold' do
      before do
        result.instance_variable_set(:@track, { 'title_distance' => 95, 'artist_distance' => 40 })
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
