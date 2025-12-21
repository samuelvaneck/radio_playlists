# frozen_string_literal: true

describe Api::V1::SongsController do
  let(:artist) { create :artist }
  let(:song) { create :song, artists: [artist] }
  let(:radio_station_one) { create :radio_station }
  let(:radio_station_two) { create :radio_station }
  let(:radio_station_three) { create :radio_station }
  let(:json) { JSON.parse(response.body).with_indifferent_access }

  before do
    create(:air_play, song:, radio_station: radio_station_one)
    create(:air_play, song:, radio_station: radio_station_two)
    create_list(:air_play, 5, radio_station: radio_station_three)
  end

  describe 'GET #index' do
    subject(:get_index) { get :index, params: { format: :json } }

    context 'with no search params' do
      it 'returns status OK/200' do
        get_index
        expect(response.status).to eq 200
      end

      it 'returns all the air plays songs' do
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
        expect(json[:data].map { |song| song[:id] }).to include(song.id.to_s)
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

  describe 'GET #time_analytics' do
    subject(:get_time_analytics) { get :time_analytics, params: { id: song.id, format: :json } }

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
        get :time_analytics, params: { id: song.id, radio_station_ids: [radio_station_one.id], format: :json }
      end

      it 'returns filtered lifecycle_stats' do
        get_time_analytics_filtered
        expect(json[:lifecycle_stats][:total_plays]).to eq(1)
      end
    end

    context 'with weeks parameter' do
      subject(:get_time_analytics_with_weeks) do
        get :time_analytics, params: { id: song.id, weeks: 8, format: :json }
      end

      it 'returns status OK/200' do
        get_time_analytics_with_weeks
        expect(response.status).to eq 200
      end
    end
  end

  describe 'GET #chart_positions' do
    subject(:get_chart_positions) { get :chart_positions, params: { id: song.id, format: :json } }

    let(:chart_yesterday) { create :chart, date: Time.zone.yesterday, chart_type: 'songs' }
    let(:chart_week_ago) { create :chart, date: 1.week.ago.to_date, chart_type: 'songs' }
    let(:chart_month_ago) { create :chart, date: 1.month.ago.to_date, chart_type: 'songs' }
    let(:chart_year_ago) { create :chart, date: 1.year.ago.to_date, chart_type: 'songs' }
    let(:response_body) { JSON.parse(response.body) }

    before do
      create :chart_position, chart: chart_yesterday, positianable: song, position: 1, counts: 50
      create :chart_position, chart: chart_week_ago, positianable: song, position: 3, counts: 30
      create :chart_position, chart: chart_month_ago, positianable: song, position: 5, counts: 20
      create :chart_position, chart: chart_year_ago, positianable: song, position: 10, counts: 10
    end

    it 'returns status OK/200' do
      get_chart_positions
      expect(response.status).to eq 200
    end

    it 'returns an array of chart positions' do
      get_chart_positions
      expect(response_body).to be_an(Array)
    end

    it 'returns positions with correct structure', :aggregate_failures do
      get_chart_positions
      expect(response_body.first).to have_key('date')
      expect(response_body.first).to have_key('position')
      expect(response_body.first).to have_key('counts')
    end

    context 'with default period (month)' do
      it 'includes positions from the last month' do
        get_chart_positions
        dates = response_body.map { |p| p['date'] }
        expect(dates).to include(chart_week_ago.date.to_s)
      end

      it 'excludes positions older than a month' do
        get_chart_positions
        dates = response_body.map { |p| p['date'] }
        expect(dates).not_to include(chart_year_ago.date.to_s)
      end
    end

    context 'with period=week' do
      subject(:get_chart_positions_week) do
        get :chart_positions, params: { id: song.id, period: 'week', format: :json }
      end

      it 'includes positions from the last week' do
        get_chart_positions_week
        dates = response_body.map { |p| p['date'] }
        expect(dates).to include(chart_yesterday.date.to_s)
      end
    end

    context 'with period=year' do
      subject(:get_chart_positions_year) do
        get :chart_positions, params: { id: song.id, period: 'year', format: :json }
      end

      it 'includes positions from the last year' do
        get_chart_positions_year
        dates = response_body.map { |p| p['date'] }
        expect(dates).to include(chart_month_ago.date.to_s)
      end
    end

    context 'with period=all' do
      subject(:get_chart_positions_all) do
        get :chart_positions, params: { id: song.id, period: 'all', format: :json }
      end

      it 'includes all positions' do
        get_chart_positions_all
        dates = response_body.map { |p| p['date'] }
        expect(dates).to include(chart_year_ago.date.to_s)
      end
    end

    context 'with invalid period' do
      subject(:get_chart_positions_invalid) do
        get :chart_positions, params: { id: song.id, period: 'invalid', format: :json }
      end

      it 'defaults to month period' do
        get_chart_positions_invalid
        dates = response_body.map { |p| p['date'] }
        expect(dates).not_to include(chart_year_ago.date.to_s)
      end
    end
  end
end
