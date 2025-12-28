# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'AirPlays API', type: :request do
  path '/api/v1/air_plays' do
    get 'List recent air plays' do
      tags 'AirPlays'
      produces 'application/json'
      description 'Use either period OR start_time/end_time (mutually exclusive). Returns 400 if both provided.'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :period, in: :query, type: :string, required: false,
                description: 'Time period: hour, two_hours, four_hours, eight_hours, twelve_hours, day, week, ' \
                             'month, year, all. Mutually exclusive with start_time/end_time'
      parameter name: :start_time, in: :query, type: :string, required: false,
                description: 'Custom start time (YYYY-MM-DDTHH:MM). Mutually exclusive with period'
      parameter name: :end_time, in: :query, type: :string, required: false,
                description: 'Custom end time (YYYY-MM-DDTHH:MM). Defaults to current time'
      parameter name: 'radio_station_ids[]', in: :query, type: :array, items: { type: :integer },
                required: false, description: 'Filter by radio station IDs'
      parameter name: :search_term, in: :query, type: :string, required: false,
                description: 'Search by song title or artist name'

      response '200', 'Air plays retrieved successfully' do
        let!(:air_play) { create(:air_play) }

        run_test!
      end
    end
  end
end
