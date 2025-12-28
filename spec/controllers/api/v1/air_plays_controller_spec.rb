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

    context 'when filtered by start_time' do
      let(:old_air_play) { create :air_play, radio_station: radio_station_one, song: song_one, broadcasted_at: 3.hours.ago }

      before { old_air_play }

      context 'with hour' do
        subject(:get_index) { get :index, params: { format: :json, start_time: 'hour' } }

        it 'only fetches the air plays from the last hour' do
          get_index
          expect(json[:data].map { |p| p[:id] }).not_to include(old_air_play.id.to_s)
        end
      end

      context 'with two_hours' do
        subject(:get_index) { get :index, params: { format: :json, start_time: 'two_hours' } }

        it 'only fetches the air plays from the last two hours' do
          get_index
          expect(json[:data].map { |p| p[:id] }).not_to include(old_air_play.id.to_s)
        end
      end

      context 'with four_hours' do
        subject(:get_index) { get :index, params: { format: :json, start_time: 'four_hours' } }

        it 'includes air plays from the last four hours' do
          get_index
          expect(json[:data].map { |p| p[:id] }).to include(old_air_play.id.to_s)
        end
      end

      context 'with eight_hours' do
        subject(:get_index) { get :index, params: { format: :json, start_time: 'eight_hours' } }

        it 'includes air plays from the last eight hours' do
          get_index
          expect(json[:data].map { |p| p[:id] }).to include(old_air_play.id.to_s)
        end
      end

      context 'with twelve_hours' do
        subject(:get_index) { get :index, params: { format: :json, start_time: 'twelve_hours' } }

        it 'includes air plays from the last twelve hours' do
          get_index
          expect(json[:data].map { |p| p[:id] }).to include(old_air_play.id.to_s)
        end
      end
    end

    context 'when filtered by end_time' do
      let(:radio_station_three) { create :radio_station }
      let(:recent_air_play) { create :air_play, radio_station: radio_station_three, song: song_one, broadcasted_at: 30.minutes.ago }
      let(:old_air_play) { create :air_play, radio_station: radio_station_three, song: song_two, broadcasted_at: 3.hours.ago }

      before do
        recent_air_play
        old_air_play
      end

      context 'with end_time before recent air plays' do
        subject(:get_index) do
          get :index, params: {
            format: :json,
            start_time: 'day',
            end_time: 2.hours.ago.strftime('%Y-%m-%dT%R'),
            radio_station_ids: [radio_station_three.id]
          }
        end

        it 'includes air plays before the end_time' do
          get_index
          expect(json[:data].map { |p| p[:id] }).to include(old_air_play.id.to_s)
        end

        it 'excludes air plays after the end_time' do
          get_index
          expect(json[:data].map { |p| p[:id] }).not_to include(recent_air_play.id.to_s)
        end
      end

      context 'with start_time and end_time range' do
        subject(:get_index) do
          get :index, params: {
            format: :json,
            start_time: 4.hours.ago.strftime('%Y-%m-%dT%R'),
            end_time: 2.hours.ago.strftime('%Y-%m-%dT%R'),
            radio_station_ids: [radio_station_three.id]
          }
        end

        it 'only fetches air plays within the time range' do
          get_index
          expect(json[:data].map { |p| p[:id] }).to contain_exactly(old_air_play.id.to_s)
        end
      end
    end
  end
end
