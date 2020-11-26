# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Song do
  let(:artist_1) { FactoryBot.create :artist }
  let(:song_1) { FactoryBot.create :song, artists: [artist_1] }
  let(:artist_2) { FactoryBot.create :artist }
  let(:song_2) { FactoryBot.create :song, artists: [artist_2] }
  let(:radiostation) { FactoryBot.create :radiostation }
  let(:playlist_1) { FactoryBot.create :generalplaylist, :filled, song: song_1 }
  let(:playlist_2) { FactoryBot.create :generalplaylist, :filled, song: song_2, radiostation: radiostation }
  let(:playlist_3) { FactoryBot.create :generalplaylist, :filled, song: song_2, radiostation: radiostation }

  let(:song_drown) { FactoryBot.create :song, title: 'Drown', artists: [artist_martin_garrix, artist_clinton_kane] }
  let(:artist_martin_garrix) { FactoryBot.create :artist, name: 'Martin Garrix' }
  let(:artist_clinton_kane) { FactoryBot.create :artist, name: 'Clinton Kane' }
  let(:song_breaking_me) { FactoryBot.create :song, title: 'Breaking Me Ft A7s', artists: [artist_topic] }
  let(:artist_topic) { FactoryBot.create :artist, name: 'Topic' }
  let(:song_stuck_with_u) { FactoryBot.create :song, title: 'Stuck With U', artists: [artist_justin_bieber, artist_ariana_grande] }
  let(:artist_justin_bieber) { FactoryBot.create :artist, name: 'Justin Bieber' }
  let(:artist_ariana_grande) { FactoryBot.create :artist, name: 'Ariana Grande' }

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

    context 'with radiostation_id params present' do
      it 'only returns the songs played on the radiostation' do
        results = Song.search({ radiostation_id: radiostation.id })

        expect(results).to include playlist_2, playlist_3
      end
    end
  end

  describe '#group_and_count' do
    it 'groups and counts the songs' do
      results = Song.group_and_count(Generalplaylist.all)

      expect(results).to eq [[song_2.id, 2], [song_1.id, 1]]
    end
  end

  describe '#spotify_search' do
    context 'when having multiple song hits' do
      it 'returns the song single and not karaoke version' do
        result = song_drown.spotify_search([artist_martin_garrix, artist_clinton_kane])
        expect(result.album.album_type).to eq 'single'

        result = song_breaking_me.spotify_search([artist_topic])
        expect(result.album.album_type).to eq 'single'

        result = song_stuck_with_u.spotify_search([artist_justin_bieber, artist_ariana_grande])
        expect(result.album.album_type).to eq 'single'
        expect(result.artists.map(&:name)).to contain_exactly 'Justin Bieber', 'Ariana Grande'
      end
    end
  end

  describe '#cleanup' do
    context 'if the song has no playlists' do
      let!(:song_no_playlist) { FactoryBot.create :song }
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
      let(:artist_one_song) { FactoryBot.create :artist }
      let!(:song_one) { FactoryBot.create :song, artists: [artist_one_song] }
      it 'does not destroy the artist' do
        expect {
          song_one.cleanup
        }.to change(Artist, :count).by(-1)
      end
    end

    context 'if the song artist has more song' do
      let(:artist_multiple_song) { FactoryBot.create :artist }
      let!(:song_one) { FactoryBot.create :song, artists: [artist_multiple_song] }
      let!(:song_two) { FactoryBot.create :song, artists: [artist_multiple_song] }
      it 'destroy' do
        expect {
          song_two.cleanup
        }.to change(Artist, :count).by(0)
      end
    end
  end
end
