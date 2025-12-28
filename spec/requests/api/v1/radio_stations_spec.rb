# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'RadioStations API', type: :request do
  path '/api/v1/radio_stations' do
    get 'List all radio stations' do
      tags 'Radio Stations'
      produces 'application/json'

      response '200', 'Radio stations retrieved successfully' do
        let!(:radio_station) { create(:radio_station) }

        run_test!
      end
    end
  end

  path '/api/v1/radio_stations/{id}' do
    get 'Get a radio station' do
      tags 'Radio Stations'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Radio station ID'

      response '200', 'Radio station retrieved successfully' do
        let(:radio_station) { create(:radio_station) }
        let(:id) { radio_station.id }

        run_test!
      end

      response '404', 'Radio station not found' do
        let(:id) { 0 }

        run_test!
      end
    end
  end

  path '/api/v1/radio_stations/{id}/status' do
    get 'Get radio station status' do
      tags 'Radio Stations'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Radio station ID'

      response '200', 'Radio station status retrieved successfully' do
        let(:radio_station) { create(:radio_station) }
        let(:id) { radio_station.id }

        run_test!
      end
    end
  end

  path '/api/v1/radio_stations/{id}/data' do
    get 'Get radio station data' do
      tags 'Radio Stations'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Radio station ID'

      response '200', 'Radio station data retrieved successfully' do
        let(:radio_station) { create(:radio_station) }
        let(:id) { radio_station.id }

        run_test!
      end
    end
  end

  path '/api/v1/radio_stations/{id}/classifiers' do
    get 'Get radio station audio classifiers' do
      tags 'Radio Stations'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Radio station ID'

      response '200', 'Radio station classifiers retrieved successfully' do
        let(:radio_station) { create(:radio_station) }
        let(:id) { radio_station.id }

        run_test!
      end
    end
  end

  path '/api/v1/radio_stations/last_played_songs' do
    get 'Get last played songs for all stations' do
      tags 'Radio Stations'
      produces 'application/json'

      response '200', 'Last played songs retrieved successfully' do
        let!(:radio_station) { create(:radio_station) }

        run_test!
      end
    end
  end

  path '/api/v1/radio_stations/new_played_songs' do
    get 'Get newly played songs across all stations' do
      tags 'Radio Stations'
      produces 'application/json'
      description 'Use either period OR start_time/end_time (mutually exclusive). Returns 400 if both provided.'
      parameter name: :period, in: :query, type: :string, required: false,
                description: 'Time period: hour, two_hours, four_hours, eight_hours, twelve_hours, day, week, ' \
                             'month, year, all. Mutually exclusive with start_time/end_time'
      parameter name: :start_time, in: :query, type: :string, required: false,
                description: 'Custom start time (YYYY-MM-DDTHH:MM). Mutually exclusive with period'
      parameter name: :end_time, in: :query, type: :string, required: false,
                description: 'Custom end time (YYYY-MM-DDTHH:MM). Defaults to current time'
      parameter name: 'radio_station_ids[]', in: :query, type: :array, items: { type: :integer },
                required: false, description: 'Filter by radio station IDs'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'

      response '200', 'New played songs retrieved successfully' do
        let(:period) { 'week' }
        let!(:radio_station) { create(:radio_station) }

        run_test!
      end

      response '400', 'Period or start_time parameter is required' do
        let(:period) { nil }

        run_test!
      end
    end
  end

  path '/api/v1/radio_stations/{id}/stream_proxy' do
    get 'Proxy radio station stream' do
      tags 'Radio Stations'
      produces 'audio/mpeg'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Radio station ID'

      response '200', 'Stream proxied successfully' do
        let(:radio_station) { create(:radio_station, stream_url: 'https://example.com/stream') }
        let(:id) { radio_station.id }

        before do
          allow(Net::HTTP).to receive(:start).and_return(nil)
        end

        run_test! do
          # Stream endpoint - just verify it doesn't error
        end
      end

      response '400', 'No stream URL configured' do
        let(:radio_station) { create(:radio_station, stream_url: nil) }
        let(:id) { radio_station.id }

        run_test!
      end
    end
  end
end
