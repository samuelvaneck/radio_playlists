# frozen_string_literal: true

describe Api::V1::ArtistsController do
  let(:artist_one) { create :artist }
  let(:song_one) { create :song, artists: [artist_one] }
  let(:artist_two) { create :artist }
  let(:song_two) { create :song, artists: [artist_two] }
  let(:artist_three) { create :artist }
  let(:song_three) { create :song, artists: [artist_three] }
  let(:radio_station_one) { create :radio_station }
  let(:radio_station_two) { create :radio_station }
  let(:radio_station_three) { create :radio_station }
  let(:json) { JSON.parse(response.body).with_indifferent_access }

  before do
    create(:playlist, song: song_one, radio_station: radio_station_one)
    create(:playlist, song: song_two, radio_station: radio_station_two)
    create_list(:playlist, 5, song: song_three, radio_station: radio_station_three)
  end

  describe 'GET #index' do
    subject(:get_index) { get :index, params: { format: :json } }

    context 'with no search params' do
      it 'returns status OK/200' do
        get_index
        expect(response.status).to eq 200
      end

      it 'returns all the playlists artists' do
        get_index
        expect(json[:data].count).to eq(3)
      end
    end

    context 'with search params' do
      it 'only returns the search artist' do
        get :index, params: { format: :json, search_term: artist_one.name }

        expect(json[:data].map { |artist| artist[:id] }).to contain_exactly(artist_one.id.to_s)
      end
    end

    context 'when filtering by radio station' do
      it 'only returns the artists that are played by the radio station' do
        get :index, params: { format: :json, radio_station_ids: [radio_station_one.id] }

        expect(json[:data].map { |artist| artist[:id] }).to contain_exactly(artist_one.id.to_s)
      end
    end
  end
end
