# frozen_string_literal: true

require 'ostruct'
require 'rails_helper'

describe TrackExtractor::SpotifyTrackFinder do
  subject(:finder) { described_class.new(played_song:) }

  let(:played_song) do
    OpenStruct.new(
      title: 'Test Song',
      artist_name: 'Test Artist',
      spotify_url: nil,
      isrc_code: nil
    )
  end

  let(:track_result) { instance_double(Spotify::TrackFinder::Result) }

  before do
    allow(Spotify::TrackFinder::Result).to receive(:new).and_return(track_result)
    allow(track_result).to receive(:execute)
  end

  describe '#find' do
    context 'when played_song is blank' do
      let(:played_song) { nil }

      it 'returns nil' do
        expect(finder.find).to be_nil
      end
    end

    context 'when played_song is present' do
      it 'returns a track result' do
        expect(finder.find).to eq(track_result)
      end

      it 'executes the track finder' do
        finder.find
        expect(track_result).to have_received(:execute)
      end
    end

    context 'with spotify_url as search url' do
      let(:played_song) do
        OpenStruct.new(
          title: 'Test Song',
          artist_name: 'Test Artist',
          spotify_url: 'spotify:search:test',
          isrc_code: nil
        )
      end

      it 'passes spotify_search_url to the track finder' do
        finder.find
        expect(Spotify::TrackFinder::Result)
          .to have_received(:new)
          .with(artists: 'Test Artist', title: 'Test Song', spotify_search_url: 'spotify:search:test')
      end
    end

    context 'with spotify_url as track url' do
      let(:played_song) do
        OpenStruct.new(
          title: 'Test Song',
          artist_name: 'Test Artist',
          spotify_url: 'https://open.spotify.com/track/abc123',
          isrc_code: nil
        )
      end

      it 'passes spotify_track_id to the track finder' do
        finder.find
        expect(Spotify::TrackFinder::Result)
          .to have_received(:new)
          .with(artists: 'Test Artist', title: 'Test Song', spotify_track_id: 'abc123')
      end
    end

    context 'with existing_song_spotify_id' do
      let(:artist) { create(:artist, name: 'Test Artist') }

      before { create(:song, title: 'Test Song', id_on_spotify: 'existing123', artists: [artist]) }

      it 'uses the existing song spotify id' do
        finder.find
        expect(Spotify::TrackFinder::Result)
          .to have_received(:new)
          .with(artists: 'Test Artist', title: 'Test Song', spotify_track_id: 'existing123')
      end

      context 'when spotify_url is present' do
        let(:played_song) do
          OpenStruct.new(
            title: 'Test Song',
            artist_name: 'Test Artist',
            spotify_url: 'https://open.spotify.com/track/newtrack456',
            isrc_code: nil
          )
        end

        it 'prefers the spotify_url over existing_song_spotify_id' do
          finder.find
          expect(Spotify::TrackFinder::Result)
            .to have_received(:new)
            .with(artists: 'Test Artist', title: 'Test Song', spotify_track_id: 'newtrack456')
        end
      end

      context 'with case-insensitive title matching' do
        let(:played_song) do
          OpenStruct.new(
            title: 'TEST SONG',
            artist_name: 'Test Artist',
            spotify_url: nil,
            isrc_code: nil
          )
        end

        it 'finds the existing song regardless of case' do
          finder.find
          expect(Spotify::TrackFinder::Result)
            .to have_received(:new)
            .with(artists: 'Test Artist', title: 'TEST SONG', spotify_track_id: 'existing123')
        end
      end

      context 'with case-insensitive artist matching' do
        let(:played_song) do
          OpenStruct.new(
            title: 'Test Song',
            artist_name: 'TEST ARTIST',
            spotify_url: nil,
            isrc_code: nil
          )
        end

        it 'finds the existing song regardless of artist case' do
          finder.find
          expect(Spotify::TrackFinder::Result)
            .to have_received(:new)
            .with(artists: 'TEST ARTIST', title: 'Test Song', spotify_track_id: 'existing123')
        end
      end
    end

    context 'with multiple artists in artist_name' do
      let(:first_artist) { create(:artist, name: 'Artist One') }
      let(:second_artist) { create(:artist, name: 'Artist Two') }

      before { create(:song, title: 'Collab Song', id_on_spotify: 'collab123', artists: [first_artist, second_artist]) }

      context 'when separated by feat.' do
        let(:played_song) do
          OpenStruct.new(
            title: 'Collab Song',
            artist_name: 'Artist One feat. Artist Two',
            spotify_url: nil,
            isrc_code: nil
          )
        end

        it 'finds the existing song by matching artists' do
          finder.find
          expect(Spotify::TrackFinder::Result)
            .to have_received(:new)
            .with(artists: 'Artist One feat. Artist Two', title: 'Collab Song', spotify_track_id: 'collab123')
        end
      end

      context 'when separated by &' do
        let(:played_song) do
          OpenStruct.new(
            title: 'Collab Song',
            artist_name: 'Artist One & Artist Two',
            spotify_url: nil,
            isrc_code: nil
          )
        end

        it 'finds the existing song by matching artists' do
          finder.find
          expect(Spotify::TrackFinder::Result)
            .to have_received(:new)
            .with(artists: 'Artist One & Artist Two', title: 'Collab Song', spotify_track_id: 'collab123')
        end
      end

      context 'when separated by ft.' do
        let(:played_song) do
          OpenStruct.new(
            title: 'Collab Song',
            artist_name: 'Artist One ft. Artist Two',
            spotify_url: nil,
            isrc_code: nil
          )
        end

        it 'finds the existing song by matching artists' do
          finder.find
          expect(Spotify::TrackFinder::Result)
            .to have_received(:new)
            .with(artists: 'Artist One ft. Artist Two', title: 'Collab Song', spotify_track_id: 'collab123')
        end
      end
    end

    context 'when no existing song is found' do
      let(:played_song) do
        OpenStruct.new(
          title: 'Unknown Song',
          artist_name: 'Unknown Artist',
          spotify_url: nil,
          isrc_code: nil
        )
      end

      it 'does not pass spotify_track_id' do
        finder.find
        expect(Spotify::TrackFinder::Result).to have_received(:new).with(
          artists: 'Unknown Artist',
          title: 'Unknown Song'
        )
      end
    end

    context 'when artist_name is blank' do
      let(:played_song) do
        OpenStruct.new(
          title: 'Test Song',
          artist_name: '',
          spotify_url: nil,
          isrc_code: nil
        )
      end

      it 'does not attempt to find existing song' do
        finder.find
        expect(Spotify::TrackFinder::Result).to have_received(:new).with(
          artists: '',
          title: 'Test Song'
        )
      end
    end

    context 'when title is blank' do
      let(:played_song) do
        OpenStruct.new(
          title: '',
          artist_name: 'Test Artist',
          spotify_url: nil,
          isrc_code: nil
        )
      end

      it 'does not attempt to find existing song' do
        finder.find
        expect(Spotify::TrackFinder::Result).to have_received(:new).with(
          artists: 'Test Artist',
          title: ''
        )
      end
    end

    context 'when existing song has no spotify id' do
      let(:artist) { create(:artist, name: 'Test Artist') }

      before { create(:song, title: 'Test Song', id_on_spotify: nil, artists: [artist]) }

      it 'does not pass spotify_track_id' do
        finder.find
        expect(Spotify::TrackFinder::Result).to have_received(:new).with(artists: 'Test Artist', title: 'Test Song')
      end
    end

    context 'when finding existing song by ISRC' do
      let(:artist) { create(:artist, name: 'Different Artist Name') }
      let(:played_song) do
        OpenStruct.new(
          title: 'Some Title',
          artist_name: 'Completely Different Artist',
          spotify_url: nil,
          isrc_code: 'USRC12345678'
        )
      end

      before { create(:song, title: 'Original Title', isrc: 'USRC12345678', id_on_spotify: 'isrc_match123', artists: [artist]) }

      it 'finds the existing song by ISRC even when artist names do not match' do
        finder.find
        expect(Spotify::TrackFinder::Result)
          .to have_received(:new)
          .with(artists: 'Completely Different Artist', title: 'Some Title', spotify_track_id: 'isrc_match123')
      end
    end

    context 'when ISRC matches but song has no Spotify ID' do
      let(:artist) { create(:artist, name: 'Test Artist') }
      let(:played_song) do
        OpenStruct.new(
          title: 'Test Song',
          artist_name: 'Test Artist',
          spotify_url: nil,
          isrc_code: 'USRC12345678'
        )
      end

      before { create(:song, title: 'Test Song', isrc: 'USRC12345678', id_on_spotify: nil, artists: [artist]) }

      it 'falls back to artist + title matching' do
        finder.find
        expect(Spotify::TrackFinder::Result).to have_received(:new).with(artists: 'Test Artist', title: 'Test Song')
      end
    end

    context 'when artist name has extra featuring info' do
      let(:artist) { create(:artist, name: 'Ed Sheeran') }
      let(:played_song) do
        OpenStruct.new(
          title: 'Perfect',
          artist_name: 'Ed Sheeran feat. Beyoncé',
          spotify_url: nil,
          isrc_code: nil
        )
      end

      before { create(:song, title: 'Perfect', id_on_spotify: 'perfect123', artists: [artist]) }

      it 'finds the existing song using fuzzy artist matching' do
        finder.find
        expect(Spotify::TrackFinder::Result)
          .to have_received(:new)
          .with(artists: 'Ed Sheeran feat. Beyoncé', title: 'Perfect', spotify_track_id: 'perfect123')
      end
    end

    context 'when recognized artist is substring of existing artist' do
      let(:artist) { create(:artist, name: 'Ed Sheeran feat. Beyoncé') }
      let(:played_song) do
        OpenStruct.new(
          title: 'Perfect',
          artist_name: 'Ed Sheeran',
          spotify_url: nil,
          isrc_code: nil
        )
      end

      before { create(:song, title: 'Perfect', id_on_spotify: 'perfect456', artists: [artist]) }

      it 'finds the existing song when recognized artist is contained in existing artist name' do
        finder.find
        expect(Spotify::TrackFinder::Result)
          .to have_received(:new)
          .with(artists: 'Ed Sheeran', title: 'Perfect', spotify_track_id: 'perfect456')
      end
    end

    context 'when fuzzy matching should not match completely different artists' do
      let(:artist) { create(:artist, name: 'Taylor Swift') }
      let(:played_song) do
        OpenStruct.new(
          title: 'Love Story',
          artist_name: 'Ed Sheeran',
          spotify_url: nil,
          isrc_code: nil
        )
      end

      before { create(:song, title: 'Love Story', id_on_spotify: 'lovestory123', artists: [artist]) }

      it 'does not find the song when artists are completely different' do
        finder.find
        expect(Spotify::TrackFinder::Result)
          .to have_received(:new)
          .with(artists: 'Ed Sheeran', title: 'Love Story')
      end
    end

    context 'when multiple songs have the same title' do
      let(:artist1) { create(:artist, name: 'Ed Sheeran') }
      let(:artist2) { create(:artist, name: 'Taylor Swift') }
      let(:played_song) do
        OpenStruct.new(
          title: 'Beautiful',
          artist_name: 'Ed Sheeran feat. Someone',
          spotify_url: nil,
          isrc_code: nil
        )
      end

      before do
        create(:song, title: 'Beautiful', id_on_spotify: 'taylor_beautiful', artists: [artist2])
        create(:song, title: 'Beautiful', id_on_spotify: 'ed_beautiful', artists: [artist1])
      end

      it 'finds the correct song based on fuzzy artist matching' do
        finder.find
        expect(Spotify::TrackFinder::Result)
          .to have_received(:new)
          .with(artists: 'Ed Sheeran feat. Someone', title: 'Beautiful', spotify_track_id: 'ed_beautiful')
      end
    end
  end
end
