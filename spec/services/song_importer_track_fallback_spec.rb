# frozen_string_literal: true

describe SongImporter do
  describe '#track fallback behavior' do
    let(:radio_station) { create(:radio_station) }
    let(:song_importer) { described_class.new(radio_station:) }
    let(:played_song) do
      instance_double(
        SongRecognizer,
        title:,
        artist_name:,
        spotify_url: nil,
        isrc_code: nil,
        broadcasted_at: Time.current
      )
    end

    before do
      song_importer.instance_variable_set(:@played_song, played_song)
    end

    describe 'Faith Hill - Where Are You Christmas' do
      let(:title) { 'Where Are You Christmas' }
      let(:spotify_low_match_response) do
        {
          'tracks' => {
            'items' => [
              {
                'id' => 'spotify123',
                'name' => 'Christmas Time', # Different title - low match
                'popularity' => 50,
                'album' => {
                  'artists' => [{ 'id' => 'artist1', 'name' => 'Faith Hill' }],
                  'album_type' => 'album',
                  'images' => [{ 'url' => 'https://example.com/image.jpg' }],
                  'release_date' => '2000-11-14',
                  'release_date_precision' => 'day'
                },
                'artists' => [{ 'id' => 'artist1', 'name' => 'Faith Hill' }],
                'external_ids' => { 'isrc' => 'USWD19900001' },
                'external_urls' => { 'spotify' => 'https://open.spotify.com/track/spotify123' },
                'preview_url' => 'https://example.com/preview.mp3'
              }
            ]
          }
        }
      end
      let(:itunes_valid_match_response) do
        {
          'resultCount' => 1,
          'results' => [
            {
              'trackId' => 123_456_789,
              'trackName' => 'Where Are You Christmas',
              'artistName' => 'Faith Hill',
              'artistId' => 987_654,
              'collectionName' => 'How the Grinch Stole Christmas',
              'trackViewUrl' => 'https://music.apple.com/us/album/where-are-you-christmas/123456789',
              'previewUrl' => 'https://audio-ssl.itunes.apple.com/preview.m4a',
              'artworkUrl100' => 'https://is1-ssl.mzstatic.com/image/100x100bb.jpg',
              'releaseDate' => '2000-11-14T08:00:00Z'
            }
          ]
        }
      end
      let(:artist_name) { 'Faith Hill' }

      before do
        # Stub Spotify token request
        stub_request(:post, 'https://accounts.spotify.com/api/token')
          .to_return(
            status: 200,
            body: { access_token: 'test_token', token_type: 'Bearer', expires_in: 3600 }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub Spotify search - returns a track with low similarity (different song)
        stub_request(:get, %r{api\.spotify\.com/v1/search})
          .to_return(
            status: 200,
            body: spotify_low_match_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub iTunes search - returns the correct track with high similarity
        stub_request(:get, %r{itunes\.apple\.com/search})
          .to_return(
            status: 200,
            body: itunes_valid_match_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub Spotify artist lookup (called when processing track artists)
        stub_request(:get, %r{api\.spotify\.com/v1/artists/})
          .to_return(
            status: 200,
            body: { 'id' => 'artist1', 'name' => 'Faith Hill', 'images' => [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub Deezer search (may be called as fallback)
        stub_request(:get, %r{api\.deezer\.com/search})
          .to_return(
            status: 200,
            body: { 'data' => [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'falls back to iTunes when Spotify returns no valid match' do
        expect(song_importer.send(:track)).to be_present
      end

      it 'returns a track that responds to itunes_song_url' do
        expect(song_importer.send(:track)).to respond_to(:itunes_song_url)
      end

      it 'returns a track with a valid iTunes song URL' do
        expect(song_importer.send(:track).itunes_song_url).to include('music.apple.com')
      end

      it 'returns a track with a title' do
        expect(song_importer.send(:track).title).to eq('Where Are You Christmas')
      end

      it 'returns a track with artists' do
        expect(song_importer.send(:track).artists).to be_present
      end

      it 'returns a track that is a valid match' do
        expect(song_importer.send(:track).valid_match?).to be true
      end

      it 'does not use Spotify track because it has no valid match' do
        expect(song_importer.send(:spotify_track)&.valid_match?).to be false
      end
    end
  end
end
