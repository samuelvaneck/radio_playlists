# frozen_string_literal: true

# == Schema Information
#
# Table name: songs
#
#  id                                :bigint           not null, primary key
#  cached_chart_positions            :jsonb
#  cached_chart_positions_updated_at :datetime
#  id_on_spotify                     :string
#  id_on_youtube                     :string
#  isrc                              :string
#  release_date                      :date
#  search_text                       :text
#  spotify_artwork_url               :string
#  spotify_preview_url               :string
#  spotify_song_url                  :string
#  title                             :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#
# Indexes
#
#  index_songs_on_release_date  (release_date)
#  index_songs_on_search_text   (search_text)
#
describe Song do
  let(:artist_one) { create :artist }
  let(:song_one) { create :song, artists: [artist_one] }
  let(:artist_two) { create :artist }
  let(:song_two) { create :song, artists: [artist_two] }
  let(:radio_station) { create :radio_station }
  let(:playlist_one) { create :playlist, song: song_one }
  let(:playlist_two) { create :playlist, song: song_two, radio_station: }
  let(:playlist_three) { create :playlist, song: song_two, radio_station: }

  let(:song_drown) { create :song, title: 'Drown', artists: [artist_martin_garrix, artist_clinton_kane] }
  let(:artist_martin_garrix) { create :artist, name: 'Martin Garrix' }
  let(:artist_clinton_kane) { create :artist, name: 'Clinton Kane' }
  let(:song_breaking_me) { create :song, title: 'Breaking Me Ft A7s', artists: [artist_topic] }
  let(:artist_topic) { create :artist, name: 'Topic' }
  let(:song_stuck_with_u) { create :song, title: 'Stuck With U', artists: [artist_justin_bieber, artist_ariana_grande] }
  let(:artist_justin_bieber) { create :artist, name: 'Justin Bieber' }
  let(:artist_ariana_grande) { create :artist, name: 'Ariana Grande' }

  before do
    playlist_one
    playlist_two
    playlist_three
  end

  describe '#self.most_played' do
    context 'with search term params present' do
      subject(:most_played_with_search_term) do
        Song.most_played({ search_term: song_one.title })
      end

      it 'only returns the songs matching the search term' do
        expect(most_played_with_search_term).to contain_exactly song_one
      end
    end

    context 'with radio_station_id params present' do
      subject(:most_played_with_radio_station_id) do
        Song.most_played({ radio_station_id: radio_station.id })
      end

      it 'only returns the songs played on the radio station' do
        expect(most_played_with_radio_station_id).to include(song_two)
      end

      it 'adds a counter attribute on the song' do
        expect(most_played_with_radio_station_id[0].counter).to eq 2
      end
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
          song_one.cleanup
        }.not_to change(Song, :count)
      end
    end

    context 'if the song artist has no more songs' do
      let(:artist_one_song) { create :artist }
      let!(:song_one) { create :song, artists: [artist_one_song] }

      it 'does not destroy the artist' do
        expect {
          song_one.cleanup
        }.not_to change(Artist, :count)
      end
    end

    context 'if the song artist has more song' do
      let(:artist_multiple_song) { create :artist }
      let!(:song_one) { create :song, artists: [artist_multiple_song] }
      let!(:song_two) { create :song, artists: [artist_multiple_song] }
      it 'destroy' do
        expect {
          song_two.cleanup
        }.not_to change(Artist, :count)
      end
    end
  end

  describe '#update_artists' do
    let(:ed_sheeran) { create(:artist, name: 'Ed Sheeran') }
    let(:taylor_swift) { create(:artist, name: 'Taylor Swift') }
    let(:song) { create(:song, title: 'The Joker and the Queen', artists: [ed_sheeran]) }

    before { song }

    context 'when adding a new artists' do
      it 'creates a new record in the join table ArtistsSong' do
        expect do
          song.update_artists([ed_sheeran, taylor_swift])
        end.to change(ArtistsSong, :count).by(1)
      end
    end

    context 'when adding a duplicate artists' do
      it 'does not create a new record in the join table' do
        expect do
          song.update_artists([ed_sheeran])
        end.not_to change(ArtistsSong, :count)
      end
    end

    context 'when no artists are given as argument' do
      it 'does not change the song artists' do
        expect do
          song.update_artists(nil)
        end.not_to change(ArtistsSong, :count)
      end
    end

    context 'when given a single artists as argument' do
      before do
        song.update_artists(taylor_swift)
        song.reload
      end

      it 'assigns the given artist(s) as song artists' do
        expect(song.artists).to contain_exactly(taylor_swift)
      end
    end

    context 'when given an arrray of artists as arugments' do
      before do
        song.update_artists([taylor_swift])
        song.reload
      end

      it 'assigns the given artist(s) as song artists' do
        expect(song.artists).to contain_exactly(taylor_swift)
      end
    end
  end

  describe '#set_search_text' do
    let(:artist) { create(:artist, name: 'Ed Sheeran') }
    let(:song) { create(:song, title: 'Shape of You', artists: [artist]) }

    it 'updates search_text before song creation' do
      expect(song.reload.search_text).to eq('Ed Sheeran Shape of You')
    end
  end

  describe '#update_search_text' do
    let(:artist) { create(:artist, name: 'Ed Sheeran') }
    let(:song) { create(:song, title: 'Shape of You', artists: [artist]) }

    it 'updates search_text when the title changes' do
      song.update(title: 'Perfect')
      expect(song.reload.search_text).to eq('Ed Sheeran Perfect')
    end

    it 'updates search_text when an artist is added' do
      new_artist = create(:artist, name: 'Beyoncé')
      song.update_artists([artist, new_artist])
      expect(song.reload.search_text).to eq('Ed Sheeran Beyoncé Shape of You')
    end
  end
end
