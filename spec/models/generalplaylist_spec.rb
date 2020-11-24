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
  let(:radio_station) { FactoryBot.create :radiostation }
  let(:playlist_1) { FactoryBot.create :generalplaylist, :filled, song: song_1, radiostation: radio_station }
  let(:playlist_2) { FactoryBot.create :generalplaylist, :filled, song: song_2, radiostation: radio_station }
  let(:playlist_3) { FactoryBot.create :generalplaylist, :filled, song: song_2, radiostation: radio_station }

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

    context 'with radiostations params' do
      it 'returns the playlist played on the radiostation' do
        expect(Generalplaylist.search({ radiostation_id: radio_station.id })).to include playlist_2, playlist_3
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
        new_playlist_item = Generalplaylist.new(broadcast_timestamp: playlist_1.broadcast_timestamp, song: playlist_1.song, radiostation: playlist_1.radiostation)

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
end
