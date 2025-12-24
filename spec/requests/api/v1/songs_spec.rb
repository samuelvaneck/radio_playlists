# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Songs API', type: :request do
  path '/api/v1/songs' do
    get 'List songs' do
      tags 'Songs'
      produces 'application/json'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :time, in: :query, type: :string, required: false,
                description: 'Time period filter (day, week, month, year, all)'
      parameter name: :start_date, in: :query, type: :string, format: :date, required: false,
                description: 'Start date for filtering'
      parameter name: :end_date, in: :query, type: :string, format: :date, required: false,
                description: 'End date for filtering'
      parameter name: :radio_station_id, in: :query, type: :integer, required: false,
                description: 'Filter by radio station'

      response '200', 'Songs retrieved successfully' do
        let!(:song) { create(:song) }
        let!(:air_play) { create(:air_play, song: song) }

        run_test!
      end
    end
  end

  path '/api/v1/songs/{id}' do
    get 'Get a song' do
      tags 'Songs'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Song ID'

      response '200', 'Song retrieved successfully' do
        let(:song) { create(:song) }
        let(:id) { song.id }

        run_test!
      end

      response '404', 'Song not found' do
        let(:id) { 0 }

        run_test!
      end
    end
  end

  path '/api/v1/songs/{id}/graph_data' do
    get 'Get song play count graph data' do
      tags 'Songs'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Song ID'
      parameter name: :time, in: :query, type: :string, required: false,
                description: 'Time period (day, week, month, year, all)'

      response '200', 'Graph data retrieved successfully' do
        let(:song) { create(:song) }
        let(:id) { song.id }
        let(:time) { 'week' }

        run_test!
      end
    end
  end

  path '/api/v1/songs/{id}/chart_positions' do
    get 'Get song chart positions over time' do
      tags 'Songs'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Song ID'
      parameter name: :period, in: :query, type: :string, required: false,
                description: 'Time period (week, month, year, all). Default: month'

      response '200', 'Chart positions retrieved successfully' do
        let(:song) { create(:song) }
        let(:id) { song.id }

        run_test!
      end
    end
  end

  path '/api/v1/songs/{id}/time_analytics' do
    get 'Get song time-based analytics' do
      tags 'Songs'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Song ID'
      parameter name: 'radio_station_ids[]', in: :query, type: :array, items: { type: :integer },
                required: false, description: 'Filter by radio station IDs'
      parameter name: :weeks, in: :query, type: :integer, required: false,
                description: 'Number of weeks for trend analysis. Default: 4'

      response '200', 'Time analytics retrieved successfully' do
        let(:song) { create(:song) }
        let(:id) { song.id }

        run_test!
      end
    end
  end

  path '/api/v1/songs/{id}/air_plays' do
    get 'Get song air plays' do
      tags 'Songs'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Song ID'
      parameter name: :period, in: :query, type: :string, required: false,
                description: 'Time period (day, week, month, year, all). Default: day'
      parameter name: 'radio_station_ids[]', in: :query, type: :array, items: { type: :integer },
                required: false, description: 'Filter by radio station IDs'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'

      response '200', 'Air plays retrieved successfully' do
        let(:song) { create(:song) }
        let!(:air_play) { create(:air_play, song: song, broadcasted_at: 1.hour.ago) }
        let(:id) { song.id }

        run_test!
      end
    end
  end
end
