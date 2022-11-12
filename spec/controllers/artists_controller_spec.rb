# frozen_string_literal: true

describe ArtistsController do
  let(:artist) { create :artist }
  let(:song) { create :song, artists: [artist] }
  let(:playlist_1) { create :playlist, :filled, song: }
  let(:playlist_2) { create :playlist, :filled, song: }
  let(:playlists) { create_list :playlist, 5, :filled }
  let(:json) do
    JSON(response.body).sort_by { |_artist, counter| counter }
                       .reverse
  end

  describe 'GET #index' do
    context 'with no search params' do
      let(:expected) do
        [ArtistSerializer.new(Artist.find(artist.id)).serializable_hash.as_json, 2]
      end

      before do
        playlist_1
        playlist_2
        playlists
        get :index, params: { format: :json }
      end
      it 'returns status OK/200' do
        expect(response.status).to eq 200
      end

      it 'returns all the playlists artists' do
        expect(json.first).to eq(expected)
      end
    end

    context 'with search params' do
      before do
        playlist_1
        playlist_2
        playlists
      end
      it 'only returns the search artist' do
        get :index, params: { format: :json, search_term: artist.name }

        expect(json).to eq [[ArtistSerializer.new(Artist.find(artist.id)).serializable_hash.as_json, 2]]
      end
    end

    context 'filtering by radio station' do
      before do
        playlist_1
        playlist_2
        playlists
      end
      it 'only returns the artists that are played by the radio station' do
        get :index, params: { format: :json, radio_station_id: playlist_1.radio_station.id }

        expect(json).to eq [[ArtistSerializer.new(Artist.find(artist.id)).serializable_hash.as_json, 1]]
      end
    end
  end
end
