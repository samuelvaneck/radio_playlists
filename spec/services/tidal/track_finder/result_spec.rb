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

  def search_response(tracks:, artists:)
    {
      'data' => {
        'id' => 'shape of you',
        'type' => 'searchResults',
        'attributes' => { 'trackingId' => 'abc' },
        'relationships' => { 'tracks' => { 'data' => tracks.map { |t| { 'id' => t['id'], 'type' => 'tracks' } } } }
      },
      'included' => tracks + artists
    }
  end

  def stub_search(body)
    stub_request(:get, %r{openapi\.tidal\.com/v2/searchresults}).to_return(
      status: 200,
      body: body.to_json,
      headers: { 'Content-Type' => 'application/vnd.api+json' }
    )
  end

  describe '#execute' do
    let(:ed_sheeran) { { 'id' => '100', 'type' => 'artists', 'attributes' => { 'name' => 'Ed Sheeran' } } }
    let(:track_resource) do
      {
        'id' => '12345', 'type' => 'tracks',
        'attributes' => {
          'title' => 'Shape of You', 'isrc' => 'GBAHS1600786', 'duration' => 'PT3M53S',
          'explicit' => false, 'popularity' => 0.5
        },
        'relationships' => { 'artists' => { 'data' => [{ 'id' => '100', 'type' => 'artists' }] } }
      }
    end

    context 'when the search returns a single matching track' do
      before do
        stub_search(search_response(tracks: [track_resource], artists: [ed_sheeran]))
        result.execute
      end

      it 'returns the title' do
        expect(result.title).to eq('Shape of You')
      end

      it 'returns the Tidal id' do
        expect(result.id).to eq('12345')
      end

      it 'returns the song URL' do
        expect(result.tidal_song_url).to eq('https://tidal.com/browse/track/12345')
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

      it 'returns nil artwork (album not included in this iteration)' do
        expect(result.tidal_artwork_url).to be_nil
      end
    end

    context 'when the search returns several tracks' do
      let(:low_pop_track) do
        track_resource.merge('id' => 'low', 'attributes' => track_resource['attributes'].merge('popularity' => 0.1))
      end
      let(:high_pop_track) do
        track_resource.merge('id' => 'high', 'attributes' => track_resource['attributes'].merge('popularity' => 0.95))
      end

      before do
        stub_search(search_response(tracks: [low_pop_track, high_pop_track], artists: [ed_sheeran]))
        result.execute
      end

      it 'picks the most popular track' do
        expect(result.id).to eq('high')
      end
    end

    context 'when an ISRC is supplied and search returns multiple ISRCs' do
      let(:isrc) { 'GBAHS1600786' }
      let(:matching_track) do
        track_resource.merge('id' => 'matches', 'attributes' => track_resource['attributes'].merge('popularity' => 0.2))
      end
      let(:wrong_isrc_track) do
        track_resource.merge(
          'id' => 'mismatch',
          'attributes' => track_resource['attributes'].merge('isrc' => 'OTHER000000', 'popularity' => 0.99)
        )
      end

      before do
        stub_search(search_response(tracks: [wrong_isrc_track, matching_track], artists: [ed_sheeran]))
        result.execute
      end

      it 'narrows to tracks with the matching ISRC even when a wrong-ISRC track is more popular' do
        expect(result.id).to eq('matches')
      end
    end

    context 'when an ISRC is supplied but no result has that ISRC' do
      let(:isrc) { 'NONEXISTENT' }
      let(:other_track) do
        track_resource.merge('id' => 'other', 'attributes' => track_resource['attributes'].merge('isrc' => 'OTHER000000'))
      end

      before do
        stub_search(search_response(tracks: [other_track], artists: [ed_sheeran]))
        result.execute
      end

      it 'falls back to the full pool and validates via artist/title distance' do
        expect(result.id).to eq('other')
      end
    end

    context 'when the title does not pass the threshold' do
      let(:wrong_title_track) do
        track_resource.merge('attributes' => track_resource['attributes'].merge('title' => 'Completely Different Song'))
      end

      before do
        stub_search(search_response(tracks: [wrong_title_track], artists: [ed_sheeran]))
        result.execute
      end

      it 'rejects the match' do
        expect(result.track).to be_nil
      end
    end

    context 'when the artist does not pass the threshold' do
      let(:wrong_artist) { { 'id' => '999', 'type' => 'artists', 'attributes' => { 'name' => 'Some Other Artist' } } }
      let(:wrong_artist_track) do
        track_resource.merge('relationships' => { 'artists' => { 'data' => [{ 'id' => '999', 'type' => 'artists' }] } })
      end

      before do
        stub_search(search_response(tracks: [wrong_artist_track], artists: [wrong_artist]))
        result.execute
      end

      it 'rejects the match' do
        expect(result.track).to be_nil
      end
    end

    context 'when search returns nothing' do
      before do
        stub_search('data' => { 'id' => 'q', 'type' => 'searchResults', 'attributes' => {} }, 'included' => [])
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
