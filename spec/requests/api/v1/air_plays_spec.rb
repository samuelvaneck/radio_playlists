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
        example 'application/json', :example, {
          data: [
            {
              id: '1',
              type: 'air_play',
              attributes: {
                id: 1,
                broadcasted_at: '2024-12-01T14:30:00Z',
                song: {
                  id: 1,
                  title: 'Bohemian Rhapsody',
                  spotify_artwork_url: 'https://i.scdn.co/image/abc123',
                  artists: [{ id: 1, name: 'Queen' }]
                },
                radio_station: {
                  id: 1,
                  name: 'Radio 538',
                  slug: 'radio-538'
                }
              }
            },
            {
              id: '2',
              type: 'air_play',
              attributes: {
                id: 2,
                broadcasted_at: '2024-12-01T14:26:00Z',
                song: {
                  id: 2,
                  title: 'Blinding Lights',
                  spotify_artwork_url: 'https://i.scdn.co/image/def456',
                  artists: [{ id: 2, name: 'The Weeknd' }]
                },
                radio_station: {
                  id: 2,
                  name: 'Qmusic',
                  slug: 'qmusic'
                }
              }
            }
          ],
          total_entries: 1500,
          total_pages: 63,
          current_page: 1
        }

        let!(:air_play) { create(:air_play) }

        run_test!
      end
    end
  end
end
