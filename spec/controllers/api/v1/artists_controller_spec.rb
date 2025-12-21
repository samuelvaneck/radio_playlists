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

  describe 'GET #chart_positions' do
    subject(:get_chart_positions) { get :chart_positions, params: { id: artist_one.id, format: :json } }

    let(:chart_yesterday) { create :chart, date: Time.zone.yesterday, chart_type: 'artists' }
    let(:chart_week_ago) { create :chart, date: 1.week.ago.to_date, chart_type: 'artists' }
    let(:chart_month_ago) { create :chart, date: 1.month.ago.to_date, chart_type: 'artists' }
    let(:chart_year_ago) { create :chart, date: 1.year.ago.to_date, chart_type: 'artists' }
    let(:response_body) { JSON.parse(response.body) }

    before do
      create :chart_position, chart: chart_yesterday, positianable: artist_one, position: 1, counts: 50
      create :chart_position, chart: chart_week_ago, positianable: artist_one, position: 3, counts: 30
      create :chart_position, chart: chart_month_ago, positianable: artist_one, position: 5, counts: 20
      create :chart_position, chart: chart_year_ago, positianable: artist_one, position: 10, counts: 10
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
        get :chart_positions, params: { id: artist_one.id, period: 'week', format: :json }
      end

      it 'includes positions from the last week' do
        get_chart_positions_week
        dates = response_body.map { |p| p['date'] }
        expect(dates).to include(chart_yesterday.date.to_s)
      end
    end

    context 'with period=year' do
      subject(:get_chart_positions_year) do
        get :chart_positions, params: { id: artist_one.id, period: 'year', format: :json }
      end

      it 'includes positions from the last year' do
        get_chart_positions_year
        dates = response_body.map { |p| p['date'] }
        expect(dates).to include(chart_month_ago.date.to_s)
      end
    end

    context 'with period=all' do
      subject(:get_chart_positions_all) do
        get :chart_positions, params: { id: artist_one.id, period: 'all', format: :json }
      end

      it 'includes all positions' do
        get_chart_positions_all
        dates = response_body.map { |p| p['date'] }
        expect(dates).to include(chart_year_ago.date.to_s)
      end
    end

    context 'with invalid period' do
      subject(:get_chart_positions_invalid) do
        get :chart_positions, params: { id: artist_one.id, period: 'invalid', format: :json }
      end

      it 'defaults to month period' do
        get_chart_positions_invalid
        dates = response_body.map { |p| p['date'] }
        expect(dates).not_to include(chart_year_ago.date.to_s)
      end
    end
  end

  describe 'GET #air_plays' do
    subject(:get_air_plays) { get :air_plays, params: { id: artist_one.id, format: :json } }

    it 'returns status OK/200' do
      get_air_plays
      expect(response.status).to eq 200
    end

    it 'returns air plays for the artist' do
      get_air_plays
      expect(json[:data].count).to eq(1)
    end

    it 'returns pagination data', :aggregate_failures do
      get_air_plays
      expect(json).to have_key(:total_entries)
      expect(json).to have_key(:total_pages)
      expect(json).to have_key(:current_page)
    end

    context 'with period=week' do
      subject(:get_air_plays_week) do
        get :air_plays, params: { id: artist_one.id, period: 'week', format: :json }
      end

      let!(:old_air_play) do
        air_play = create(:air_play, song: song_one, radio_station: radio_station_one, broadcasted_at: 2.weeks.ago)
        air_play.update_column(:created_at, 2.weeks.ago)
        air_play
      end

      it 'excludes air plays older than a week' do
        get_air_plays_week
        air_play_ids = json[:data].map { |ap| ap[:id].to_i }
        expect(air_play_ids).not_to include(old_air_play.id)
      end
    end

    context 'with radio_station_ids filter' do
      subject(:get_air_plays_filtered) do
        get :air_plays, params: { id: artist_three.id, radio_station_ids: [radio_station_three.id], format: :json }
      end

      it 'returns only air plays from filtered radio stations' do
        get_air_plays_filtered
        expect(json[:data].count).to eq(5)
      end
    end
  end
end
