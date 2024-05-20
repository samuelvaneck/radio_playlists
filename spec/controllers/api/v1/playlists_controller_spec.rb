# frozen_string_literal: true

describe Api::V1::PlaylistsController do
  let(:radio_station_one) { create :radio_station }
  let(:radio_station_two) { create :radio_station }
  let(:artist_one) { create :artist }
  let(:song_one) { create :song, artists: [artist_one] }
  let(:artist_two) { create :artist }
  let(:song_two) { create :song, artists: [artist_two] }
  let(:playlist) { create :playlist, radio_station: radio_station_one, song: song_one }
  let(:playlists) { create_list :playlist, 5, radio_station: radio_station_two, song: song_two }

  describe 'GET #index' do
    before do
      playlist
      playlists
    end

    context 'with no search params' do
      it 'renders the index page' do
        get :index

        expect(response).to render_template :index
        expect(response.status).to eq 200
      end

      it 'sets the playlists' do
        get :index, format: :json

        expect(JSON.parse(response.body)['data'].count).to eq 6
      end
    end

    context 'with search param' do
      it 'only fetches the playlists that matches the song title or artitst name' do
        get :index, params: { format: :json, search_term: song_one.title }

        expect(JSON.parse(response.body)['data'][0]['id']).to eq playlist.id.to_s
      end
    end

    context 'when filtered by radio_station' do
      it 'only fetches the playlists that are played on the radio_station' do
        get :index, params: { format: :json, radio_station_id: radio_station_one.id }

        expect(JSON.parse(response.body)['data'][0]['id']).to eq playlist.id.to_s
      end
    end
  end
end
