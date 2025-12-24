# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'AirPlays API', type: :request do
  path '/api/v1/air_plays' do
    get 'List recent air plays' do
      tags 'AirPlays'
      produces 'application/json'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :time, in: :query, type: :string, required: false,
                description: 'Time period filter (day, week, month, year, all)'
      parameter name: :radio_station_id, in: :query, type: :integer, required: false,
                description: 'Filter by radio station'

      response '200', 'Air plays retrieved successfully' do
        let!(:air_play) { create(:air_play) }

        run_test!
      end
    end
  end
end
