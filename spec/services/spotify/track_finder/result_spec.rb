# frozen_string_literal: true

require 'rails_helper'

describe Spotify::TrackFinder::Result, :use_vcr do
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

      it 'has valid match scores' do
        expect(finder.valid_match?).to be true
      end

      it 'sets artist and title distance', :aggregate_failures do
        expect(finder.matched_artist_distance).to be >= Spotify::Base::ARTIST_SIMILARITY_THRESHOLD
        expect(finder.matched_title_distance).to be >= Spotify::Base::TITLE_SIMILARITY_THRESHOLD
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

  describe '#fetch_spotify_track with match scores' do
    let(:spotify_track_id) { 'test_track_id' }

    let(:spotify_track_response) do
      {
        'album' => {
          'album_type' => 'album',
          'artists' => [{ 'name' => response_artist, 'id' => 'artist_id',
                          'external_urls' => { 'spotify' => 'https://open.spotify.com/artist/artist_id' } }],
          'images' => [{ 'url' => 'https://example.com/image.jpg' }],
          'name' => 'Test Album',
          'release_date' => '2023-01-01',
          'release_date_precision' => 'day'
        },
        'artists' => [{ 'name' => response_artist, 'id' => 'artist_id',
                        'external_urls' => { 'spotify' => 'https://open.spotify.com/artist/artist_id' } }],
        'name' => response_title,
        'id' => 'test_track_id',
        'popularity' => 75,
        'duration_ms' => 200_000,
        'explicit' => false,
        'external_ids' => { 'isrc' => 'TEST12345678' },
        'external_urls' => { 'spotify' => 'https://open.spotify.com/track/test_track_id' },
        'preview_url' => 'https://example.com/preview.mp3'
      }
    end

    let(:response_artist) { artists }
    let(:response_title) { title }

    let(:find_by_id_instance) { instance_double(Spotify::TrackFinder::FindById, execute: spotify_track_response) }
    let(:artist_finder_instance) { instance_double(Spotify::ArtistFinder, info: { 'name' => response_artist }) }

    before do
      allow(Spotify::TrackFinder::FindById).to receive(:new).and_return(find_by_id_instance)
      allow(Spotify::ArtistFinder).to receive(:new).and_return(artist_finder_instance)
      finder.execute
    end

    context 'when artist and title match exactly' do
      it 'returns a valid match', :aggregate_failures do
        expect(finder.valid_match?).to be true
        expect(finder.matched_artist_distance).to eq(100)
        expect(finder.matched_title_distance).to eq(100)
      end
    end

    context 'when artist name has a small prefix difference' do
      let(:artists) { 'Doobie Brothers' }
      let(:response_artist) { 'The Doobie Brothers' }
      let(:response_title) { 'China Grove' }

      it 'computes non-zero artist distance' do
        expect(finder.matched_artist_distance).to be > 0
      end

      it 'falls below threshold for "The" prefix' do
        expect(finder.matched_artist_distance).to be < Spotify::Base::ARTIST_SIMILARITY_THRESHOLD
      end
    end

    context 'when artist name has a minor spelling variation' do
      let(:artists) { 'Alanis Morissette' }
      let(:response_artist) { 'Alanis Morrissette' }

      it 'returns a valid match when above threshold' do
        expect(finder.valid_match?).to be true
      end

      it 'computes artist distance above threshold' do
        expect(finder.matched_artist_distance).to be >= Spotify::Base::ARTIST_SIMILARITY_THRESHOLD
      end
    end

    context 'when title has extra parenthetical suffix' do
      let(:artists) { 'Doobie Brothers' }
      let(:title) { 'China Grove (Mono)' }
      let(:response_artist) { 'Doobie Brothers' }
      let(:response_title) { 'China Grove' }

      it 'returns a valid match when above threshold' do
        expect(finder.valid_match?).to be true
      end

      it 'computes title distance above threshold' do
        expect(finder.matched_title_distance).to be >= Spotify::Base::TITLE_SIMILARITY_THRESHOLD
      end
    end

    context 'when artist is completely different' do
      let(:artists) { 'Ed Sheeran' }
      let(:response_artist) { 'Taylor Swift' }

      it 'returns an invalid match' do
        expect(finder.valid_match?).to be false
      end

      it 'computes artist distance below threshold' do
        expect(finder.matched_artist_distance).to be < Spotify::Base::ARTIST_SIMILARITY_THRESHOLD
      end
    end

    context 'when title is completely different' do
      let(:artists) { 'Ed Sheeran' }
      let(:response_title) { 'Thinking Out Loud' }

      it 'returns an invalid match' do
        expect(finder.valid_match?).to be false
      end

      it 'computes title distance below threshold' do
        expect(finder.matched_title_distance).to be < Spotify::Base::TITLE_SIMILARITY_THRESHOLD
      end
    end

    context 'when FindById returns nil' do
      let(:spotify_track_response) { nil }

      it 'returns an invalid match' do
        expect(finder.valid_match?).to be false
      end
    end

    context 'when FindById returns a Spotify error response' do
      let(:spotify_track_response) { { 'error' => { 'status' => 404, 'message' => 'Not found' } } }

      it 'returns an invalid match' do
        expect(finder.valid_match?).to be false
      end
    end

    context 'when search title is blank' do
      let(:title) { '' }

      it 'does not raise an error' do
        expect { finder.execute }.not_to raise_error
      end
    end

    context 'when ArtistFinder returns nil for an artist' do
      let(:artist_finder_instance) { instance_double(Spotify::ArtistFinder, info: nil) }

      it 'filters out nil artists' do
        expect(finder.artists).to eq([])
      end
    end

    context 'when track has no album artists' do
      let(:spotify_track_response) do
        {
          'album' => { 'album_type' => 'album', 'artists' => [],
                       'images' => [], 'name' => 'Album', 'release_date' => '2023-01-01',
                       'release_date_precision' => 'day' },
          'artists' => [{ 'name' => 'Ed Sheeran', 'id' => 'artist_id',
                          'external_urls' => { 'spotify' => 'https://open.spotify.com/artist/artist_id' } }],
          'name' => 'Celestial', 'id' => 'test_track_id', 'popularity' => 75,
          'duration_ms' => 200_000, 'explicit' => false,
          'external_ids' => { 'isrc' => 'TEST12345678' },
          'external_urls' => { 'spotify' => 'https://open.spotify.com/track/test_track_id' },
          'preview_url' => nil
        }
      end

      it 'computes artist distance as zero' do
        expect(finder.matched_artist_distance).to eq(0)
      end
    end
  end
end
