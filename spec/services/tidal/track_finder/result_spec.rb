# frozen_string_literal: true

require 'rails_helper'

describe Tidal::TrackFinder::Result do
  subject(:result) { described_class.new(artists: artists, title: title, isrc: isrc) }

  let(:artists) { 'Bruno Mars' }
  let(:title) { 'I Just Might' }
  let(:isrc) { nil }

  before do
    allow(Tidal::Token).to receive(:new).and_return(instance_double(Tidal::Token, token: 'fake_token'))
  end

  def search_response(tracks, artists: [{ 'id' => '3658521', 'name' => 'Bruno Mars' }])
    artist_resources = artists.map { |a| { 'id' => a['id'], 'type' => 'artists', 'attributes' => { 'name' => a['name'] } } }
    {
      'data' => {
        'id' => 'q', 'type' => 'searchResults',
        'attributes' => { 'trackingId' => 'abc' },
        'relationships' => { 'tracks' => { 'data' => tracks.map { |t| { 'id' => t['id'], 'type' => 'tracks' } } } }
      },
      'included' => tracks + artist_resources
    }
  end

  def stub_search(body)
    stub_request(:get, %r{openapi\.tidal\.com/v2/searchResults}).to_return(
      status: 200,
      body: body.to_json,
      headers: { 'Content-Type' => 'application/vnd.api+json' }
    )
  end

  def track_resource(id:, title:, isrc:, popularity:, artist_ids: %w[3658521])
    {
      'id' => id, 'type' => 'tracks',
      'attributes' => {
        'title' => title, 'isrc' => isrc, 'duration' => 'PT3M33S',
        'explicit' => false, 'popularity' => popularity
      },
      'relationships' => {
        'artists' => {
          'data' => artist_ids.map { |aid| { 'id' => aid, 'type' => 'artists' } },
          'links' => { 'self' => "/tracks/#{id}/relationships/artists?countryCode=NL" }
        }
      }
    }
  end

  describe '#execute' do
    context 'when search returns the matching ISRC' do
      let(:isrc) { 'USAT22509144' }

      let(:tracks) do
        [
          track_resource(id: '5274607', title: 'Just the Way You Are', isrc: 'USAT21001269', popularity: 0.85),
          track_resource(id: '67237704', title: "That's What I Like", isrc: 'USAT21602948', popularity: 0.82),
          track_resource(id: '488282494', title: 'I Just Might', isrc: 'USAT22509144', popularity: 0.72),
          track_resource(id: '498194649', title: 'I Just Might (Austin Millz Remix)', isrc: 'USAT22600280', popularity: 0.41)
        ]
      end

      before do
        stub_search(search_response(tracks))
        result.execute
      end

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
      let(:tracks) do
        [
          track_resource(id: '5274607', title: 'Just the Way You Are', isrc: 'USAT21001269', popularity: 0.85),
          track_resource(id: '488282494', title: 'I Just Might', isrc: 'USAT22509144', popularity: 0.72),
          track_resource(id: '492008674', title: 'I Just Might (Originally Performed by Bruno Mars) [Instrumental]',
                         isrc: 'QZPJ32532049', popularity: 0.11)
        ]
      end

      before do
        stub_search(search_response(tracks))
        result.execute
      end

      it 'rejects "Just the Way You Are" via title distance even though it is more popular' do
        expect(result.id).to eq('488282494')
      end
    end

    context 'when ISRC is provided but no candidate matches it' do
      let(:isrc) { 'NONEXISTENT' }
      let(:tracks) do
        [
          track_resource(id: '488282494', title: 'I Just Might', isrc: 'USAT22509144', popularity: 0.72),
          track_resource(id: '5274607', title: 'Just the Way You Are', isrc: 'USAT21001269', popularity: 0.85)
        ]
      end

      before do
        stub_search(search_response(tracks))
        result.execute
      end

      it 'falls back to the full pool and lets title distance pick the right track' do
        expect(result.id).to eq('488282494')
      end
    end

    context 'when no candidate passes the title threshold' do
      let(:tracks) do
        [
          track_resource(id: 'wrong-1', title: 'Completely Different Song', isrc: 'X', popularity: 0.9),
          track_resource(id: 'wrong-2', title: 'Another Mismatch', isrc: 'Y', popularity: 0.8)
        ]
      end

      before do
        stub_search(search_response(tracks))
        result.execute
      end

      it 'returns nil for track' do
        expect(result.track).to be_nil
      end
    end

    context 'when search returns no tracks' do
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

    context 'when search returns a title-matching track by a different artist', :use_vcr do
      subject(:result) { described_class.new(artists: 'Gordon', title: 'Ik Bel Je Zomaar Even Op') }

      before do
        allow(Tidal::Token).to receive(:new).and_call_original
        result.execute
      end

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
