# frozen_string_literal: true

describe Api::V1::SongsController do
  let(:artist) { create :artist }
  let(:song) { create :song, artists: [artist] }
  let!(:playlist_1) { create :playlist, :filled, song: }
  let!(:playlist_2) { create :playlist, :filled, song: }
  let!(:playlists) { create_list :playlist, 5, :filled }

  describe 'GET #index' do
    context 'with no search params' do
      let(:json) do
        JSON(response.body).sort_by { |_song, counter| counter }
                           .reverse
                           .first
      end
      let(:expected) do
        [SongSerializer.new(Song.find(song.id)).serializable_hash.as_json, 2]
      end

      before do
        get :index, params: { format: :json }
      end

      it 'returns status OK/200' do
        expect(response.status).to eq 200
      end

      it 'returns all the playlists songs' do
        expect(json).to eq expected
      end
    end

    context 'with search params' do
      let(:json) { JSON.parse(response.body) }
      let(:serialized_song) { SongSerializer.new(Song.find(song.id)).serializable_hash.as_json }

      it 'only returns the search song' do
        get :index, params: { format: :json, search_term: song.title }
        json = JSON.parse(response.body)

        expect(json).to eq [[serialized_song, 2]]
      end
    end

    context 'filtering by radio station' do
      let(:json) { JSON.parse(response.body) }
      let(:serialized_song) { SongSerializer.new(Song.find(song.id)).serializable_hash.as_json }

      it 'only returns the songs that are played by the radio_station' do
        get :index, params: { format: :json, radio_station_id: playlist_1.radio_station.id }

        expect(json).to eq [[serialized_song, 1]]
      end
    end
  end
end
