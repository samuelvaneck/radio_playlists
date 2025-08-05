# == Schema Information
#
# Table name: artists
#
#  id                                :bigint           not null, primary key
#  cached_chart_positions            :jsonb
#  cached_chart_positions_updated_at :datetime
#  genre                             :string
#  id_on_spotify                     :string
#  image                             :string
#  instagram_url                     :string
#  name                              :string
#  spotify_artist_url                :string
#  spotify_artwork_url               :string
#  website_url                       :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#
# Indexes
#
#  index_artists_on_name  (name)
#

describe Artist do
  let(:artist_one) { create :artist }
  let(:song_one) { create :song, artists: [artist_one] }
  let(:artist_two) { create :artist }
  let(:song_two) { create :song, artists: [artist_two] }
  let(:artist_three) { create :artist }
  let(:song_three) { create :song, artists: [artist_three] }
  let(:radio_station) { create :radio_station }
  let(:playlist_one) { create :playlist, song: song_one }
  let(:playlist_two) { create :playlist, song: song_two, radio_station: }
  let(:playlist_three) { create :playlist, song: song_three, radio_station: }
  let(:playlist_four) { create :playlist, song: song_three, radio_station: }

  before do
    playlist_one
    playlist_two
    playlist_three
    playlist_four
  end

  describe '#search' do
    context 'with search term params present' do
      it 'only returns the artists matching the search term' do
        results = Artist.most_played({ search_term: artist_one.name })

        expect(results).to include artist_one
      end
    end

    context 'with radio_station_id params present' do
      it 'only returns the artists played on the radio_station' do
        results = Artist.most_played({ radio_station_id: radio_station.id })

        expect(results).to include artist_two, artist_three
      end
    end
  end

  describe '#cleanup' do
    context 'if the artist has no songs' do
      let!(:artist_no_songs) { create :artist }
      it 'destroys the artist' do
        expect {
          artist_no_songs.cleanup
        }.to change(Artist, :count).by(-1)
      end
    end

    context 'if the artist has songs' do
      it 'does not destroy the artist' do
        expect {
          artist_one.cleanup
        }.not_to change(Artist, :count)
      end
    end
  end
end
