# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Generalplaylist do
  let(:artist_1) { FactoryBot.create :artist }
  let(:song_1) { FactoryBot.create :song, artists: [artist_1] }
  let(:artist_2) { FactoryBot.create :artist }
  let(:song_2) { FactoryBot.create :song, artists: [artist_2] }
  let(:artist_3) { FactoryBot.create :artist, name: 'Robin Schulz' }
  let(:song_3) { FactoryBot.create :song, artists: [artist_3] }
  let(:artist_4) { FactoryBot.create :artist, name: 'Erika Sirola' }
  let(:song_4) { FactoryBot.create :song, artists: [artist_4] }
  let(:radio_station) { FactoryBot.create :radio_station }
  let(:playlist_1) { FactoryBot.create :generalplaylist, :filled, song: song_1, radio_station: radio_station }
  let(:playlist_2) { FactoryBot.create :generalplaylist, :filled, song: song_2, radio_station: radio_station }
  let(:playlist_3) { FactoryBot.create :generalplaylist, :filled, song: song_2, radio_station: radio_station }

  describe '#search' do
    before do
      playlist_1
      playlist_2
      playlist_3
    end
    context 'with search term params' do
      it 'returns the playlists artist name or song title that matches the search terms' do
        expected = [playlist_1]

        expect(Generalplaylist.search({ search_term: song_1.title })).to eq expected
      end
    end

    context 'with radio_stations params' do
      it 'returns the playlist played on the radio station' do
        expect(Generalplaylist.search({ radio_station_id: radio_station.id })).to include playlist_2, playlist_3
      end
    end

    context 'with no params' do
      it 'returns all the playlists' do
        expect(Generalplaylist.search({})).to include playlist_1, playlist_2, playlist_3
      end
    end
  end

  describe '#today_unique_playlist_item' do
    before { playlist_1 }
    context 'with an already playlist existing item' do
      it 'fails validation' do
        new_playlist_item = Generalplaylist.new(broadcast_timestamp: playlist_1.broadcast_timestamp,
                                                song: playlist_1.song,
                                                radio_station: playlist_1.radio_station)

        expect(new_playlist_item.valid?).to eq false
      end
    end

    context 'with a unique playlist item' do
      it 'does not fail validation' do
        new_playlist_item = FactoryBot.build :generalplaylist, :filled

        expect(new_playlist_item.valid?).to eq true
      end
    end
  end

  describe '#deduplicate' do
    let!(:playlist_one) { FactoryBot.create :generalplaylist, :filled }
    context 'if there are no duplicate entries' do
      it 'does not delete the playlist item' do
        expect {
          playlist_one.deduplicate
        }.to change(Generalplaylist, :count).by(0)
      end
    end

    context 'if duplicate entries exists' do
      let!(:playlist_two) {
        playlist = FactoryBot.build :generalplaylist,
                                    :filled,
                                    radio_station: playlist_one.radio_station,
                                    broadcast_timestamp: playlist_one.broadcast_timestamp
        playlist.save(validate: false)
      }
      it 'deletes the playlist item' do
        expect {
          playlist_one.deduplicate
        }.to change(Generalplaylist, :count).by(-1)
      end
    end

    context 'if there are duplicates and the song has no more playlist items' do
      let!(:playlist_two) {
        playlist = FactoryBot.build :generalplaylist,
                                    :filled,
                                    radio_station: playlist_one.radio_station,
                                    broadcast_timestamp: playlist_one.broadcast_timestamp
        playlist.save(validate: false)
      }
      it 'deletes the song' do
        expect {
          playlist_one.deduplicate
        }.to change(Song, :count).by(-1)
      end
    end

    context 'if there are duplicates and the playlist song has more playlist items' do
      let!(:playlist_two) {
        playlist = FactoryBot.build :generalplaylist,
                                    :filled,
                                    radio_station: playlist_one.radio_station,
                                    broadcast_timestamp: playlist_one.broadcast_timestamp
        playlist.save(validate: false)
      }
      let!(:playlist_three) { FactoryBot.create :generalplaylist, :filled, song: playlist_one.song }
      it 'does not delete the song' do
        expect {
          playlist_one.deduplicate
        }.to change(Song, :count).by(0)
      end
    end
  end

  describe '#duplicate?' do
    let!(:playlist_one) { FactoryBot.create :generalplaylist, :filled }
    context 'with duplicates present' do
      let!(:playlist_two) {
        playlist = FactoryBot.build :generalplaylist,
                                    :filled,
                                    radio_station: playlist_one.radio_station,
                                    broadcast_timestamp: playlist_one.broadcast_timestamp
        playlist.save(validate: false)
      }
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
