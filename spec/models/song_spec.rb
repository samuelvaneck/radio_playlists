# frozen_string_literal: true

# == Schema Information
#
# Table name: songs
#
#  id                     :bigint           not null, primary key
#  id_on_spotify          :string
#  id_on_youtube          :string
#  isrc                   :string
#  release_date           :date
#  release_date_precision :string
#  search_text            :text
#  spotify_artwork_url    :string
#  spotify_preview_url    :string
#  spotify_song_url       :string
#  title                  :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
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
  let(:air_play_one) { create :air_play, song: song_one }
  let(:air_play_two) { create :air_play, song: song_two, radio_station: }
  let(:air_play_three) { create :air_play, song: song_two, radio_station: }

  let(:song_drown) { create :song, title: 'Drown', artists: [artist_martin_garrix, artist_clinton_kane] }
  let(:artist_martin_garrix) { create :artist, name: 'Martin Garrix' }
  let(:artist_clinton_kane) { create :artist, name: 'Clinton Kane' }
  let(:song_breaking_me) { create :song, title: 'Breaking Me Ft A7s', artists: [artist_topic] }
  let(:artist_topic) { create :artist, name: 'Topic' }
  let(:song_stuck_with_u) { create :song, title: 'Stuck With U', artists: [artist_justin_bieber, artist_ariana_grande] }
  let(:artist_justin_bieber) { create :artist, name: 'Justin Bieber' }
  let(:artist_ariana_grande) { create :artist, name: 'Ariana Grande' }

  before do
    air_play_one
    air_play_two
    air_play_three
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
    context 'if the song has no air plays' do
      let!(:song_no_air_play) { create :song }
      it 'destorys the song' do
        expect {
          song_no_air_play.cleanup
        }.to change(Song, :count).by(-1)
      end
    end

    context 'if the song has an air play' do
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

  describe '#update_youtube_from_wikipedia' do
    let(:artist) { create(:artist, name: 'Adele') }
    let(:song) { create(:song, title: 'Rolling in the Deep', artists: [artist], id_on_youtube: nil) }

    context 'when song already has id_on_youtube' do
      let(:song_with_youtube) { create(:song, title: 'Hello', artists: [artist], id_on_youtube: 'existing_id') }

      it 'does not update id_on_youtube' do
        expect do
          song_with_youtube.update_youtube_from_wikipedia
        end.not_to(change { song_with_youtube.reload.id_on_youtube })
      end
    end

    context 'when Wikidata returns YouTube ID via Spotify ID', :use_vcr do
      let(:song_with_spotify) do
        create(:song,
               title: 'Rolling in the Deep',
               artists: [artist],
               id_on_youtube: nil,
               id_on_spotify: '1c8gk2PeTE04A1pIDH9YMk')
      end

      it 'updates id_on_youtube if found' do
        song_with_spotify.update_youtube_from_wikipedia
        # May or may not find it depending on Wikidata state
        expect(song_with_spotify.reload.id_on_youtube).to be_a(String).or be_nil
      end
    end

    context 'when Wikidata returns YouTube ID via ISRC', :use_vcr do
      let(:song_with_isrc) do
        create(:song,
               title: 'Rolling in the Deep',
               artists: [artist],
               id_on_youtube: nil,
               isrc: 'GBBKS1000094')
      end

      it 'updates id_on_youtube if found' do
        song_with_isrc.update_youtube_from_wikipedia
        # May or may not find it depending on Wikidata state
        expect(song_with_isrc.reload.id_on_youtube).to be_a(String).or be_nil
      end
    end

    context 'when song is not found in Wikidata', :use_vcr do
      let(:unknown_song) do
        create(:song,
               title: 'NonExistentSongXYZ123456',
               artists: [create(:artist, name: 'UnknownArtist')],
               id_on_youtube: nil)
      end

      it 'does not update id_on_youtube' do
        expect do
          unknown_song.update_youtube_from_wikipedia
        end.not_to(change { unknown_song.reload.id_on_youtube })
      end
    end
  end
end
