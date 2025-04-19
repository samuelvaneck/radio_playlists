# frozen_string_literal: true

describe Api::V1::SongsController do
  let(:artist) { create :artist }
  let(:song) { create :song, artists: [artist] }
  let(:radio_station_one) { create :radio_station }
  let(:radio_station_two) { create :radio_station }
  let(:radio_station_three) { create :radio_station }
  let(:json) { JSON.parse(response.body).with_indifferent_access }

  before do
    create(:playlist, song:, radio_station: radio_station_one)
    create(:playlist, song:, radio_station: radio_station_two)
    create_list(:playlist, 5, radio_station: radio_station_three)
  end

  describe 'GET #index' do
    subject(:get_index) { get :index, params: { format: :json } }

    context 'with no search params' do
      it 'returns status OK/200' do
        get_index
        expect(response.status).to eq 200
      end

      it 'returns all the playlists songs' do
        get_index
        expect(json[:data].count).to eq(6)
      end

      it 'returns the song one time' do
        get_index
        expect(json[:data].map { |song| song[:id] }).to include(song.id.to_s).once
      end
    end

    context 'with search params' do
      subject(:get_with_search_param) do
        get :index, params: { format: :json, search_term: song.title }
      end

      it 'only returns the search song' do
        get_with_search_param
        expect(json[:data].map { |song| song[:id] }).to contain_exactly(song.id.to_s)
      end
    end

    context 'when filtering by radio station' do
      subject(:get_with_radio_station_id) do
        get :index, params: { format: :json, radio_station_ids: [radio_station_one.id] }
      end

      it 'only returns the songs that are played by the radio_station' do
        get_with_radio_station_id

        expect(json[:data].map { |song| song[:id] }).to contain_exactly(song.id.to_s)
      end
    end
  end
end
