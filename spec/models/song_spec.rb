# frozen_string_literal: true

describe Song do
  let(:artist_1) { create :artist }
  let(:song_1) { create :song, artists: [artist_1] }
  let(:artist_2) { create :artist }
  let(:song_2) { create :song, artists: [artist_2] }
  let(:radio_station) { create :radio_station }
  let(:playlist_1) { create :playlist, :filled, song: song_1 }
  let(:playlist_2) { create :playlist, :filled, song: song_2, radio_station: }
  let(:playlist_3) { create :playlist, :filled, song: song_2, radio_station: }

  let(:song_drown) { create :song, title: 'Drown', artists: [artist_martin_garrix, artist_clinton_kane] }
  let(:artist_martin_garrix) { create :artist, name: 'Martin Garrix' }
  let(:artist_clinton_kane) { create :artist, name: 'Clinton Kane' }
  let(:song_breaking_me) { create :song, title: 'Breaking Me Ft A7s', artists: [artist_topic] }
  let(:artist_topic) { create :artist, name: 'Topic' }
  let(:song_stuck_with_u) { create :song, title: 'Stuck With U', artists: [artist_justin_bieber, artist_ariana_grande] }
  let(:artist_justin_bieber) { create :artist, name: 'Justin Bieber' }
  let(:artist_ariana_grande) { create :artist, name: 'Ariana Grande' }

  before do
    playlist_1
    playlist_2
    playlist_3
  end

  describe '#search' do
    context 'with search term params present' do
      it 'only returns the songs matching the search term' do
        results = Song.search({ search_term: song_1.title })

        expect(results).to eq [playlist_1]
      end
    end

    context 'with radio_station_id params present' do
      it 'only returns the songs played on the radio station' do
        results = Song.search({ radio_station_id: radio_station.id })

        expect(results).to include playlist_2, playlist_3
      end
    end
  end

  describe '#group_and_count' do
    let(:result) { Song.group_and_count(Playlist.all) }
    let(:second_song) do
      [song_2.id, 2]
    end
    let(:first_song) do
      [song_1.id, 1]
    end

    it 'groups and counts the songs' do
      expect(result).to eq [second_song, first_song]
    end
  end

  describe '#cleanup' do
    context 'if the song has no playlists' do
      let!(:song_no_playlist) { create :song }
      it 'destorys the song' do
        expect {
          song_no_playlist.cleanup
        }.to change(Song, :count).by(-1)
      end
    end

    context 'if the song has playlist' do
      it 'does not destroy the song' do
        expect {
          song_1.cleanup
        }.to change(Song, :count).by(0)
      end
    end

    context 'if the song artist has no more songs' do
      let(:artist_one_song) { create :artist }
      let!(:song_one) { create :song, artists: [artist_one_song] }
      it 'does not destroy the artist' do
        expect {
          song_one.cleanup
        }.to change(Artist, :count).by(-1)
      end
    end

    context 'if the song artist has more song' do
      let(:artist_multiple_song) { create :artist }
      let!(:song_one) { create :song, artists: [artist_multiple_song] }
      let!(:song_two) { create :song, artists: [artist_multiple_song] }
      it 'destroy' do
        expect {
          song_two.cleanup
        }.to change(Artist, :count).by(0)
      end
    end
  end

  describe '#update_artists' do
    let(:ed_sheeran) { create(:artist, name: 'Ed Sheeran') }
    let(:taylor_swift) { create(:artist, name: 'Taylor Swift') }
    let(:song) { create(:song, title: 'The Joker and the Queen', artists: [ed_sheeran]) }

    before { song }

    context 'when adding a new artists' do
      it 'creates a new record in the join table' do
        expect do
          song.update_artists([ed_sheeran, taylor_swift])
        end.to change(ArtistsSong, :count).by(1)
      end
    end

    context 'when adding a duplicate artists' do
      it 'does not create a new record in the join table' do
        expect do
          song.update_artists([ed_sheeran])
        end.to change(ArtistsSong, :count).by(0)
      end
    end
  end
end
