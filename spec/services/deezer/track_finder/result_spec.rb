# frozen_string_literal: true

describe Deezer::TrackFinder::Result do
  subject(:result) { described_class.new(artists: artists, title: title, isrc: isrc) }

  let(:artists) { 'Ed Sheeran' }
  let(:title) { 'Shape of You' }
  let(:isrc) { nil }

  describe '#execute' do
    context 'when the track is found by artist and title' do
      let(:deezer_response) do
        {
          'data' => [
            {
              'id' => 123_456_789,
              'title' => 'Shape of You',
              'link' => 'https://www.deezer.com/track/123456789',
              'preview' => 'https://cdns-preview.deezer.com/preview.mp3',
              'isrc' => 'GBAHS1600786',
              'artist' => { 'id' => 384, 'name' => 'Ed Sheeran' },
              'album' => {
                'id' => 1234,
                'title' => 'Divide',
                'cover' => 'https://api.deezer.com/album/1234/image',
                'cover_big' => 'https://e-cdns-images.deezer.com/images/cover/big.jpg',
                'release_date' => '2017-03-03'
              }
            }
          ]
        }
      end

      before do
        stub_request(:get, %r{api\.deezer\.com/search}).to_return(
          status: 200,
          body: deezer_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        result.execute
      end

      it 'returns the correct title' do
        expect(result.title).to eq('Shape of You')
      end

      it 'returns a valid Deezer id' do
        expect(result.id).to eq('123456789')
      end

      it 'returns a valid Deezer song URL' do
        expect(result.deezer_song_url).to include('deezer.com')
      end

      it 'returns a valid Deezer artwork URL' do
        expect(result.deezer_artwork_url).to be_present
      end

      it 'returns a valid Deezer preview URL' do
        expect(result.deezer_preview_url).to be_present
      end

      it 'returns the ISRC' do
        expect(result.isrc).to eq('GBAHS1600786')
      end
    end

    context 'when the track is found by ISRC' do
      let(:isrc) { 'GBAHS1600786' }
      let(:deezer_isrc_response) do
        {
          'id' => 123_456_789,
          'title' => 'Shape of You',
          'link' => 'https://www.deezer.com/track/123456789',
          'preview' => 'https://cdns-preview.deezer.com/preview.mp3',
          'isrc' => 'GBAHS1600786',
          'artist' => { 'id' => 384, 'name' => 'Ed Sheeran' },
          'album' => {
            'id' => 1234,
            'cover_big' => 'https://e-cdns-images.deezer.com/images/cover/big.jpg',
            'release_date' => '2017-03-03'
          }
        }
      end

      before do
        stub_request(:get, %r{api\.deezer\.com/2\.0/track/isrc:}).to_return(
          status: 200,
          body: deezer_isrc_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        result.execute
      end

      it 'returns the correct title' do
        expect(result.title).to eq('Shape of You')
      end

      it 'returns a valid Deezer id' do
        expect(result.id).to eq('123456789')
      end
    end

    context 'when the track is not found' do
      before do
        stub_request(:get, /api\.deezer\.com/).to_return(
          status: 200,
          body: { error: { type: 'DataException', message: 'no data', code: 800 } }.to_json,
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
    context 'when track has high title_distance' do
      before do
        result.instance_variable_set(:@track, { 'title_distance' => 85 })
      end

      it 'returns true' do
        expect(result.valid_match?).to be true
      end
    end

    context 'when track has low title_distance' do
      before do
        result.instance_variable_set(:@track, { 'title_distance' => 50 })
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
