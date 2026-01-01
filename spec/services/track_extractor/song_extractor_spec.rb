# frozen_string_literal: true

require 'ostruct'
require 'rails_helper'

describe TrackExtractor::SongExtractor do
  subject(:extractor) { described_class.new(played_song:, track:, artists: [artist]) }

  let(:artist) { create(:artist) }
  let(:track) do
    OpenStruct.new(
      title: 'Test Song',
      id: 'spotify123',
      isrc: 'ISRC123',
      spotify_song_url: 'https://open.spotify.com/track/spotify123',
      spotify_artwork_url: 'https://i.scdn.co/image/artwork',
      spotify_preview_url: 'https://p.scdn.co/mp3-preview/preview',
      release_date: '2023-01-01',
      release_date_precision: 'day'
    )
  end
  let(:played_song) do
    OpenStruct.new(
      title: 'Test Song',
      artist_name: 'Test Artist',
      spotify_url: 'https://open.spotify.com/track/spotify123',
      isrc_code: 'ISRC123'
    )
  end

  describe '#extract' do
    let(:song) { subject.extract }

    context 'when song does not exist' do
      it 'includes the artists' do
        expect(song.artists).to include(artist)
      end

      it 'creates a Song' do
        expect(song).to be_a(Song)
      end

      it 'sets the title' do
        expect(song.title).to eq('Test Song')
      end

      it 'sets the id on spotify' do
        expect(song.id_on_spotify).to eq('spotify123')
      end

      it 'sets the isrc code' do
        expect(song.isrc).to eq('ISRC123')
      end

      it 'sets the spotify preview URL' do
        expect(song.spotify_preview_url).to eq('https://p.scdn.co/mp3-preview/preview')
      end

      it 'sets the release date' do
        expect(song.release_date).to eq(Date.parse('2023-01-01'))
      end

      it 'sets the release date precision' do
        expect(song.release_date_precision).to eq('day')
      end
    end

    context 'when song exists' do
      let!(:existing_song) do
        create(:song,
               title: 'Test Song',
               id_on_spotify: 'spotify123',
               artists: [artist],
               spotify_preview_url: nil,
               release_date: nil)
      end

      it 'finds the existing song' do
        expect(song).to eq(existing_song)
      end

      it 'updates preview url if missing' do
        expect do
          extractor.extract
          existing_song.reload
        end.to change(existing_song, :spotify_preview_url).to('https://p.scdn.co/mp3-preview/preview')
      end

      it 'updates the release date if missing' do
        expect do
          extractor.extract
          existing_song.reload
        end.to change(existing_song, :release_date).to(Date.parse('2023-01-01'))
      end

      it 'updates the release date precision if missing' do
        expect do
          extractor.extract
          existing_song.reload
        end.to change(existing_song, :release_date_precision).to('day')
      end
    end

    context 'when song exists without Spotify data (found via ISRC)' do
      let!(:existing_song) do
        create(:song,
               title: 'Test Song',
               isrc: 'ISRC123',
               id_on_spotify: nil,
               spotify_song_url: nil,
               spotify_artwork_url: nil,
               artists: [artist])
      end

      it 'finds the existing song by ISRC' do
        expect(song).to eq(existing_song)
      end

      it 'enriches with Spotify ID' do
        expect do
          extractor.extract
          existing_song.reload
        end.to change(existing_song, :id_on_spotify).from(nil).to('spotify123')
      end

      it 'enriches with Spotify song URL' do
        expect do
          extractor.extract
          existing_song.reload
        end.to change(existing_song, :spotify_song_url).from(nil).to('https://open.spotify.com/track/spotify123')
      end

      it 'enriches with Spotify artwork URL' do
        expect do
          extractor.extract
          existing_song.reload
        end.to change(existing_song, :spotify_artwork_url).from(nil).to('https://i.scdn.co/image/artwork')
      end
    end

    context 'when song exists with Spotify data already' do
      let!(:existing_song) do
        create(:song,
               title: 'Test Song',
               id_on_spotify: 'existing_spotify_id',
               spotify_song_url: 'https://open.spotify.com/track/existing',
               spotify_artwork_url: 'https://existing-artwork.com',
               artists: [artist])
      end

      it 'does not overwrite existing Spotify ID' do
        expect do
          extractor.extract
          existing_song.reload
        end.not_to change(existing_song, :id_on_spotify)
      end

      it 'does not overwrite existing Spotify song URL' do
        expect do
          extractor.extract
          existing_song.reload
        end.not_to change(existing_song, :spotify_song_url)
      end

      it 'does not overwrite existing Spotify artwork URL' do
        expect do
          extractor.extract
          existing_song.reload
        end.not_to change(existing_song, :spotify_artwork_url)
      end
    end

    context 'when track has nil values for IDs' do
      let(:track) do
        OpenStruct.new(
          title: 'New Song',
          id: nil,
          isrc: nil,
          spotify_song_url: nil,
          spotify_artwork_url: nil,
          spotify_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: 'New Song',
          artist_name: 'Test Artist',
          spotify_url: nil,
          isrc_code: nil
        )
      end

      let!(:existing_song_with_nil_spotify_id) do
        create(:song,
               title: 'Different Song',
               id_on_spotify: nil,
               isrc: nil,
               artists: [create(:artist, name: 'Other Artist')])
      end

      it 'does not incorrectly match existing songs with nil spotify id' do
        expect(song).not_to eq(existing_song_with_nil_spotify_id)
      end

      it 'creates a new song instead of matching nil values' do
        expect(song.title).to eq('New Song')
      end
    end

    context 'when track has nil isrc but song exists with nil isrc' do
      let(:track) do
        OpenStruct.new(
          title: 'Another Song',
          id: nil,
          isrc: nil,
          spotify_song_url: nil,
          spotify_artwork_url: nil,
          spotify_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: 'Another Song',
          artist_name: 'Test Artist',
          spotify_url: nil,
          isrc_code: nil
        )
      end

      let!(:song_with_nil_isrc) do
        create(:song,
               title: 'Unrelated Song',
               id_on_spotify: nil,
               id_on_deezer: nil,
               id_on_itunes: nil,
               isrc: nil)
      end

      it 'does not match songs by nil isrc' do
        expect(song).not_to eq(song_with_nil_isrc)
      end
    end

    context 'when matching by deezer id' do
      let(:track) do
        OpenStruct.new(
          title: 'Deezer Song',
          id: 'deezer456',
          isrc: nil,
          deezer_song_url: 'https://deezer.com/track/deezer456',
          deezer_artwork_url: 'https://deezer.com/artwork',
          deezer_preview_url: 'https://deezer.com/preview',
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: 'Deezer Song',
          artist_name: 'Test Artist',
          spotify_url: nil,
          isrc_code: nil
        )
      end

      let!(:existing_deezer_song) do
        create(:song,
               title: 'Deezer Song',
               id_on_deezer: 'deezer456',
               artists: [artist])
      end

      it 'finds the song by deezer id' do
        expect(song).to eq(existing_deezer_song)
      end
    end

    context 'when matching by itunes id' do
      let(:track) do
        OpenStruct.new(
          title: 'iTunes Song',
          id: 'itunes789',
          isrc: nil,
          itunes_song_url: 'https://music.apple.com/track/itunes789',
          itunes_artwork_url: 'https://apple.com/artwork',
          itunes_preview_url: 'https://apple.com/preview',
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: 'iTunes Song',
          artist_name: 'Test Artist',
          spotify_url: nil,
          isrc_code: nil
        )
      end

      let!(:existing_itunes_song) do
        create(:song,
               title: 'iTunes Song',
               id_on_itunes: 'itunes789',
               artists: [artist])
      end

      it 'finds the song by itunes id' do
        expect(song).to eq(existing_itunes_song)
      end
    end

    context 'when track has nil deezer id but song exists with nil deezer id' do
      let(:track) do
        OpenStruct.new(
          title: 'Some Song',
          id: nil,
          isrc: nil,
          deezer_song_url: 'https://deezer.com/track/nil',
          deezer_artwork_url: nil,
          deezer_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: 'Some Song',
          artist_name: 'Test Artist',
          spotify_url: nil,
          isrc_code: nil
        )
      end

      let!(:song_with_nil_deezer_id) do
        create(:song,
               title: 'Other Song',
               id_on_deezer: nil)
      end

      it 'does not match songs by nil deezer id' do
        expect(song).not_to eq(song_with_nil_deezer_id)
      end
    end
  end
end
