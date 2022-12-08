# == Schema Information
#
# Table name: artists
#
#  id                  :bigint           not null, primary key
#  name                :string
#  image               :string
#  genre               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  spotify_artist_url  :string
#  spotify_artwork_url :string
#  id_on_spotify       :string
#
# # frozen_string_literal: true

describe Artist do
  let(:artist_1) { create :artist }
  let(:song_1) { create :song, artists: [artist_1] }
  let(:artist_2) { create :artist }
  let(:song_2) { create :song, artists: [artist_2] }
  let(:artist_3) { create :artist }
  let(:song_3) { create :song, artists: [artist_3] }
  let(:radio_station) { create :radio_station }
  let(:playlist_1) { create :playlist, :filled, song: song_1 }
  let(:playlist_2) { create :playlist, :filled, song: song_2, radio_station: }
  let(:playlist_3) { create :playlist, :filled, song: song_3, radio_station: }
  let(:playlist_4) { create :playlist, :filled, song: song_3, radio_station: }

  before do
    playlist_1
    playlist_2
    playlist_3
    playlist_4
  end

  describe '#search' do
    context 'with search term params present' do
      it 'only returns the artists matching the search term' do
        results = Artist.search({ search_term: artist_1.name })

        expect(results).to include artist_1
      end
    end

    context 'with radio_station_id params present' do
      it 'only returns the artists played on the radio_station' do
        results = Artist.search({ radio_station_id: radio_station.id })

        expect(results).to include artist_2, artist_3
      end
    end
  end

  describe '#group_and_count' do
    let(:result) do
      Artist.group_and_count(Artist.joins(:playlists).all)
    end
    let(:third_artist) do
      [artist_3.id, 2]
    end
    let(:second_artist) do
      [artist_2.id, 1]
    end
    let(:first_artist) do
      [artist_1.id, 1]
    end

    it 'groups and counts the artist' do
      expect(result).to include third_artist, second_artist, first_artist
    end
  end

  describe '#cleanup' do
    context 'if the artist has no songs' do
      let!(:artist_no_songs) { create :artist }
      it 'destorys the artist' do
        expect {
          artist_no_songs.cleanup
        }.to change(Artist, :count).by(-1)
      end
    end

    context 'if the artist has songs' do
      it 'does not destroy the artist' do
        expect {
          artist_1.cleanup
        }.to change(Artist, :count).by(0)
      end
    end
  end
end
