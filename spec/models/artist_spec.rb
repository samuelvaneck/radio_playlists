# == Schema Information
#
# Table name: artists
#
#  id                                :bigint           not null, primary key
#  name                              :string
#  image                             :string
#  genre                             :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  spotify_artist_url                :string
#  spotify_artwork_url               :string
#  id_on_spotify                     :string
#  cached_chart_positions            :jsonb
#  cached_chart_positions_updated_at :datetime
#

describe Artist do
  let(:artist_1) { create :artist }
  let(:song_1) { create :song, artists: [artist_1] }
  let(:artist_2) { create :artist }
  let(:song_2) { create :song, artists: [artist_2] }
  let(:artist_3) { create :artist }
  let(:song_3) { create :song, artists: [artist_3] }
  let(:radio_station) { create :radio_station }
  let(:playlist_1) { create :playlist, song: song_1 }
  let(:playlist_2) { create :playlist, song: song_2, radio_station: }
  let(:playlist_3) { create :playlist, song: song_3, radio_station: }
  let(:playlist_4) { create :playlist, song: song_3, radio_station: }

  before do
    playlist_1
    playlist_2
    playlist_3
    playlist_4
  end

  describe '#search' do
    context 'with search term params present' do
      it 'only returns the artists matching the search term' do
        results = Artist.most_played({ search_term: artist_1.name })

        expect(results).to include artist_1
      end
    end

    context 'with radio_station_id params present' do
      it 'only returns the artists played on the radio_station' do
        results = Artist.most_played({ radio_station_id: radio_station.id })

        expect(results).to include artist_2, artist_3
      end
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
