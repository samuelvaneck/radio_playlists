# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Artists API', type: :request do
  path '/api/v1/artists' do
    get 'List artists' do
      tags 'Artists'
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
                description: 'Search by artist name'

      response '200', 'Artists retrieved successfully' do
        let!(:artist) { create(:artist) }
        let!(:song) { create(:song, artists: [artist]) }
        let!(:air_play) { create(:air_play, song: song) }

        run_test!
      end
    end
  end

  path '/api/v1/artists/{id}' do
    get 'Get an artist' do
      tags 'Artists'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Artist ID'

      response '200', 'Artist retrieved successfully' do
        let(:artist) { create(:artist) }
        let(:id) { artist.id }

        run_test!
      end

      response '404', 'Artist not found' do
        let(:id) { 0 }

        run_test!
      end
    end
  end

  path '/api/v1/artists/{id}/graph_data' do
    get 'Get artist play count graph data' do
      tags 'Artists'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Artist ID'
      parameter name: :period, in: :query, type: :string, required: false,
                description: 'Time period (day, week, month, year, all)'

      response '200', 'Graph data retrieved successfully' do
        let(:artist) { create(:artist) }
        let(:id) { artist.id }
        let(:period) { 'week' }

        run_test!
      end
    end
  end

  path '/api/v1/artists/{id}/songs' do
    get 'Get artist songs' do
      tags 'Artists'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Artist ID'

      response '200', 'Artist songs retrieved successfully' do
        let(:artist) { create(:artist) }
        let!(:song) { create(:song, artists: [artist]) }
        let(:id) { artist.id }

        run_test!
      end
    end
  end

  path '/api/v1/artists/{id}/chart_positions' do
    get 'Get artist chart positions over time' do
      tags 'Artists'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Artist ID'
      parameter name: :period, in: :query, type: :string, required: false,
                description: 'Time period (week, month, year, all). Default: month'

      response '200', 'Chart positions retrieved successfully' do
        let(:artist) { create(:artist) }
        let(:id) { artist.id }

        run_test!
      end
    end
  end

  path '/api/v1/artists/{id}/time_analytics' do
    get 'Get artist time-based analytics' do
      tags 'Artists'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Artist ID'
      parameter name: 'radio_station_ids[]', in: :query, type: :array, items: { type: :integer },
                required: false, description: 'Filter by radio station IDs'
      parameter name: :weeks, in: :query, type: :integer, required: false,
                description: 'Number of weeks for trend analysis. Default: 4'

      response '200', 'Time analytics retrieved successfully' do
        let(:artist) { create(:artist) }
        let(:id) { artist.id }

        run_test!
      end
    end
  end

  path '/api/v1/artists/{id}/air_plays' do
    get 'Get artist air plays' do
      tags 'Artists'
      produces 'application/json'
      description 'Use either period OR start_time/end_time (mutually exclusive). Returns 400 if both provided.'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Artist ID'
      parameter name: :period, in: :query, type: :string, required: false,
                description: 'Time period: hour, two_hours, four_hours, eight_hours, twelve_hours, day, week, ' \
                             'month, year, all. Default: day. Mutually exclusive with start_time/end_time'
      parameter name: :start_time, in: :query, type: :string, required: false,
                description: 'Custom start time (YYYY-MM-DDTHH:MM). Mutually exclusive with period'
      parameter name: :end_time, in: :query, type: :string, required: false,
                description: 'Custom end time (YYYY-MM-DDTHH:MM). Defaults to current time'
      parameter name: 'radio_station_ids[]', in: :query, type: :array, items: { type: :integer },
                required: false, description: 'Filter by radio station IDs'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'

      response '200', 'Air plays retrieved successfully' do
        let(:artist) { create(:artist) }
        let!(:song) { create(:song, artists: [artist]) }
        let!(:air_play) { create(:air_play, song: song, broadcasted_at: 1.hour.ago) }
        let(:id) { artist.id }

        run_test!
      end
    end
  end

  path '/api/v1/artists/{id}/bio' do
    get 'Get artist biography from Wikipedia' do
      tags 'Artists'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Artist ID'
      parameter name: :language, in: :query, type: :string, required: false,
                description: 'Wikipedia language (en, nl, de, fr, es, it, pt, pl, ru, ja, zh). Default: en'

      response '200', 'Artist bio retrieved successfully' do
        let(:artist) { create(:artist, name: 'Coldplay') }
        let(:id) { artist.id }

        before do
          allow_any_instance_of(Wikipedia::ArtistFinder).to receive(:get_info).and_return({ # rubocop:disable RSpec/AnyInstance
                                                                                            'summary' => 'British rock band',
                                                                                            'description' => 'British rock band',
                                                                                            'url' => 'https://en.wikipedia.org/wiki/Coldplay'
                                                                                          })
        end

        run_test!
      end
    end
  end
end
