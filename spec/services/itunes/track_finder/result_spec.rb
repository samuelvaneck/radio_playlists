# frozen_string_literal: true

describe Itunes::TrackFinder::Result do
  subject(:result) { described_class.new(artists: artists, title: title) }

  let(:artists) { 'Ed Sheeran' }
  let(:title) { 'Shape of You' }

  describe '#execute' do
    context 'when the track is found by artist and title' do
      let(:itunes_response) do
        {
          'resultCount' => 1,
          'results' => [
            {
              'trackId' => 1_193_701_079,
              'trackName' => 'Shape of You',
              'artistName' => 'Ed Sheeran',
              'artistId' => 183_313_439,
              'collectionName' => 'Divide',
              'trackViewUrl' => 'https://music.apple.com/nl/album/shape-of-you/1193701392?i=1193701079',
              'previewUrl' => 'https://audio-ssl.itunes.apple.com/preview.m4a',
              'artworkUrl100' => 'https://is1-ssl.mzstatic.com/image/100x100bb.jpg',
              'releaseDate' => '2017-01-06T08:00:00Z'
            }
          ]
        }
      end

      before do
        stub_request(:get, %r{itunes\.apple\.com/search}).to_return(
          status: 200,
          body: itunes_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        result.execute
      end

      it 'returns the correct title' do
        expect(result.title).to eq('Shape of You')
      end

      it 'returns a valid iTunes id' do
        expect(result.id).to eq('1193701079')
      end

      it 'returns a valid iTunes song URL' do
        expect(result.itunes_song_url).to include('music.apple.com')
      end

      it 'returns a valid iTunes artwork URL' do
        expect(result.itunes_artwork_url).to be_present
      end

      it 'returns a valid iTunes preview URL' do
        expect(result.itunes_preview_url).to be_present
      end

      it 'returns the release date' do
        expect(result.release_date).to eq('2017-01-06')
      end

      it 'scales up the artwork URL' do
        expect(result.itunes_artwork_url).to include('600x600')
      end
    end

    context 'when the track is not found' do
      before do
        stub_request(:get, %r{itunes\.apple\.com/search}).to_return(
          status: 200,
          body: { resultCount: 0, results: [] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        result.execute
      end

      it 'returns nil for track' do
        expect(result.track).to be_nil
      end

      it 'returns nil for title' do
        expect(result.title).to be_nil
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

    context 'when title_distance is high but artist_distance is low' do
      before do
        result.instance_variable_set(:@track, { 'artist_distance' => 50, 'title_distance' => 85 })
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
