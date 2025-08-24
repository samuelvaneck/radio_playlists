# frozen_string_literal: true

describe Api::V1::AirPlaysController do
  let(:radio_station_one) { create :radio_station }
  let(:radio_station_two) { create :radio_station }
  let(:artist_one) { create :artist }
  let(:song_one) { create :song, artists: [artist_one] }
  let(:artist_two) { create :artist }
  let(:song_two) { create :song, artists: [artist_two] }
  let(:air_play) { create :air_play, radio_station: radio_station_one, song: song_one }
  let(:air_plays) { create_list :air_play, 5, radio_station: radio_station_two, song: song_two }
  let(:json) { JSON.parse(response.body).with_indifferent_access }

  describe 'GET #index' do
    before do
      air_play
      air_plays
    end

    context 'with no search params' do
      subject(:get_index) { get :index, params: { format: :json } }

      it 'renders status OK/200' do
        get_index
        expect(response.status).to eq 200
      end

      it 'sets the air_plays' do
        get_index
        expect(json[:data].count).to eq 6
      end
    end

    context 'with search param' do
      subject(:get_index) { get :index, params: { format: :json, search_term: song_one.title } }

      it 'only fetches the air plays that matches the song title or artist name' do
        get_index
        expect(json[:data].map { |p| p[:id] }).to contain_exactly(air_play.id.to_s)
      end
    end

    context 'when filtered by radio_station' do
      subject(:get_index) { get :index, params: { format: :json, radio_station_ids: [radio_station_one.id] } }

      it 'only fetches the air plays that are played on the radio_station' do
        get_index
        expect(json[:data].map { |p| p[:id] }).to contain_exactly(air_play.id.to_s)
      end
    end
  end
end
