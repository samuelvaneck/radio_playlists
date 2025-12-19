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
    create(:air_play, song: song_one, radio_station: radio_station_one)
    create(:air_play, song: song_two, radio_station: radio_station_two)
    create_list(:air_play, 5, song: song_three, radio_station: radio_station_three)
  end

  describe 'GET #index' do
    subject(:get_index) { get :index, params: { format: :json } }

    context 'with no search params' do
      it 'returns status OK/200' do
        get_index
        expect(response.status).to eq 200
      end

      it 'returns all the air plays artists' do
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

  describe 'GET #time_analytics' do
    subject(:get_time_analytics) { get :time_analytics, params: { id: artist_one.id, format: :json } }

    it 'returns status OK/200' do
      get_time_analytics
      expect(response.status).to eq 200
    end

    it 'returns peak_play_times data', :aggregate_failures do
      get_time_analytics
      expect(json).to have_key(:peak_play_times)
      expect(json[:peak_play_times]).to have_key(:peak_hour)
      expect(json[:peak_play_times]).to have_key(:peak_day)
      expect(json[:peak_play_times]).to have_key(:peak_day_name)
      expect(json[:peak_play_times]).to have_key(:hourly_distribution)
      expect(json[:peak_play_times]).to have_key(:daily_distribution)
    end

    it 'returns play_frequency_trend data' do
      get_time_analytics
      expect(json).to have_key(:play_frequency_trend)
    end

    it 'returns lifecycle_stats data', :aggregate_failures do
      get_time_analytics
      expect(json).to have_key(:lifecycle_stats)
      expect(json[:lifecycle_stats]).to have_key(:first_play)
      expect(json[:lifecycle_stats]).to have_key(:last_play)
      expect(json[:lifecycle_stats]).to have_key(:total_plays)
      expect(json[:lifecycle_stats]).to have_key(:days_active)
    end

    context 'with radio_station_ids filter' do
      subject(:get_time_analytics_filtered) do
        get :time_analytics, params: { id: artist_one.id, radio_station_ids: [radio_station_one.id], format: :json }
      end

      it 'returns filtered lifecycle_stats' do
        get_time_analytics_filtered
        expect(json[:lifecycle_stats][:total_plays]).to eq(1)
      end
    end

    context 'with weeks parameter' do
      subject(:get_time_analytics_with_weeks) do
        get :time_analytics, params: { id: artist_one.id, weeks: 8, format: :json }
      end

      it 'returns status OK/200' do
        get_time_analytics_with_weeks
        expect(response.status).to eq 200
      end
    end
  end
end
