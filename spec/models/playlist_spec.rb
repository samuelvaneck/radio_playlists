# frozen_string_literal: true

# == Schema Information
#
# Table name: playlists
#
#  id                  :bigint           not null, primary key
#  song_id             :bigint
#  radio_station_id    :bigint
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  broadcast_timestamp :datetime
#  scraper_import      :boolean          default(FALSE)
#
describe Playlist do
  let(:artist_one) { create :artist }
  let(:song_one) { create :song, artists: [artist_one] }
  let(:artist_two) { create :artist }
  let(:song_two) { create :song, artists: [artist_two] }
  let(:artist_three) { create :artist, name: 'Robin Schulz' }
  let(:song_three) { create :song, artists: [artist_three] }
  let(:artist_four) { create :artist, name: 'Erika Sirola' }
  let(:song_four) { create :song, artists: [artist_four] }
  let(:radio_station) { create :radio_station }
  let(:playlist_one) { create :playlist, :filled, song: song_one, radio_station: }
  let(:playlist_two) { create :playlist, :filled, song: song_two, radio_station: }
  let(:playlist_three) { create :playlist, :filled, song: song_two, radio_station: }

  describe '#search' do
    before do
      playlist_one
      playlist_two
      playlist_three
    end

    context 'with search term params' do
      it 'returns the playlists artist name or song title that matches the search terms' do
        expected = [playlist_one]

        expect(described_class.last_played({ search_term: song_one.title })).to eq expected
      end
    end

    context 'with radio_stations params' do
      it 'returns the playlist played on the radio station' do
        expect(described_class.last_played({ radio_station_id: radio_station.id })).to include playlist_two, playlist_three
      end
    end

    context 'with no params' do
      it 'returns all the playlists' do
        expect(described_class.last_played({})).to include playlist_one, playlist_two, playlist_three
      end
    end
  end

  describe '#today_unique_playlist_item' do
    before { playlist_one }

    context 'with an already playlist existing item' do
      it 'fails validation' do
        new_playlist_item = described_class.new(broadcast_timestamp: playlist_one.broadcast_timestamp,
                                                song: playlist_one.song,
                                                radio_station: playlist_one.radio_station)

        expect(new_playlist_item.valid?).to eq false
      end
    end

    context 'with a unique playlist item' do
      it 'does not fail validation' do
        new_playlist_item = build :playlist, :filled

        expect(new_playlist_item.valid?).to eq true
      end
    end
  end

  describe '#deduplicate' do
    let!(:playlist_one) { create :playlist, :filled }

    context 'if there are no duplicate entries' do
      it 'does not delete the playlist item' do
        expect do
          playlist_one.deduplicate
        end.to change(described_class, :count).by(0)
      end
    end

    context 'if duplicate entries exists' do
      before do
        playlist = build :playlist, :filled,
                         radio_station: playlist_one.radio_station,
                         broadcast_timestamp: playlist_one.broadcast_timestamp
        playlist.save(validate: false)
      end

      it 'deletes the playlist item' do
        expect do
          playlist_one.deduplicate
        end.to change(described_class, :count).by(-1)
      end
    end

    context 'if there are duplicates and the song has no more playlist items' do
      before do
        playlist = build :playlist, :filled,
                         radio_station: playlist_one.radio_station,
                         broadcast_timestamp: playlist_one.broadcast_timestamp
        playlist.save(validate: false)
      end

      it 'deletes the song' do
        expect do
          playlist_one.deduplicate
        end.to change(Song, :count).by(-1)
      end
    end

    context 'if there are duplicates and the playlist song has more playlist items' do
      before do
        playlist = build :playlist, :filled,
                         radio_station: playlist_one.radio_station,
                         broadcast_timestamp: playlist_one.broadcast_timestamp
        playlist.save(validate: false)
        create :playlist, :filled, song: playlist_one.song
      end

      it 'does not delete the song' do
        expect do
          playlist_one.deduplicate
        end.to change(Song, :count).by(0)
      end
    end
  end

  describe '#duplicate?' do
    let!(:playlist_one) { create :playlist, :filled }

    context 'with duplicates present' do
      before do
        playlist = build :playlist, :filled,
                         radio_station: playlist_one.radio_station,
                         broadcast_timestamp: playlist_one.broadcast_timestamp
        playlist.save(validate: false)
      end

      it 'returns true' do
        expect(playlist_one.duplicate?).to eq true
      end
    end

    context 'without duplicates' do
      it 'returns false' do
        expect(playlist_one.duplicate?).to eq false
      end
    end
  end
end
