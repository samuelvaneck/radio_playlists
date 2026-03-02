# frozen_string_literal: true

describe Api::V1::ChartsController do
  let(:json) { JSON.parse(response.body).with_indifferent_access }

  describe 'GET #search' do
    subject(:get_search) { get :search, params: { search_term: search_term, format: :json } }

    let(:artist) { create :artist, name: 'Adele' }
    let(:song_one) { create :song, title: 'Hello', artists: [artist], search_text: 'Adele Hello' }
    let(:song_two) { create :song, title: 'Rolling in the Deep', artists: [artist], search_text: 'Adele Rolling in the Deep' }
    let(:song_three) { create :song, title: 'Blinding Lights', search_text: 'The Weeknd Blinding Lights' }
    let(:chart) { create :chart, date: Time.zone.yesterday, chart_type: 'songs' }

    before do
      create :chart_position, chart: chart, positianable: song_one, position: 1, counts: 50
      create :chart_position, chart: chart, positianable: song_two, position: 5, counts: 30
      create :chart_position, chart: chart, positianable: song_three, position: 10, counts: 20
    end

    context 'when searching by song title' do
      let(:search_term) { 'Hello' }

      it 'returns status OK/200' do
        get_search
        expect(response.status).to eq 200
      end

      it 'returns only matching chart positions', :aggregate_failures do
        get_search
        expect(json[:data].count).to eq(1)
        expect(json[:data].first[:attributes][:position]).to eq(1)
      end

      it 'includes chart metadata', :aggregate_failures do
        get_search
        expect(json[:chart_date]).to eq(chart.date.to_s)
        expect(json[:chart_type]).to eq('songs')
      end
    end

    context 'when searching by artist name' do
      let(:search_term) { 'Adele' }

      it 'returns all chart positions for that artist' do
        get_search
        expect(json[:data].count).to eq(2)
      end

      it 'returns positions in order' do
        get_search
        positions = json[:data].map { |cp| cp[:attributes][:position] }
        expect(positions).to eq([1, 5])
      end
    end

    context 'when search term matches nothing' do
      let(:search_term) { 'Nonexistent Song' }

      it 'returns an empty data array' do
        get_search
        expect(json[:data]).to be_empty
      end
    end

    context 'with a specific date' do
      subject(:get_search) { get :search, params: { search_term: 'Hello', date: older_chart.date.to_s, format: :json } }

      let(:older_chart) { create :chart, date: 3.days.ago.to_date, chart_type: 'songs' }

      before do
        create :chart_position, chart: older_chart, positianable: song_one, position: 8, counts: 25
      end

      it 'searches within the specified date chart', :aggregate_failures do
        get_search
        expect(json[:chart_date]).to eq(older_chart.date.to_s)
        expect(json[:data].first[:attributes][:position]).to eq(8)
      end
    end

    context 'with previous positions' do
      let(:search_term) { 'Hello' }
      let(:previous_chart) { create :chart, date: 2.days.ago.to_date, chart_type: 'songs' }

      before do
        create :chart_position, chart: previous_chart, positianable: song_one, position: 4, counts: 35
      end

      it 'includes previous_position from the prior chart' do
        get_search
        expect(json[:data].first[:attributes][:previous_position]).to eq(4)
      end
    end
  end
end
