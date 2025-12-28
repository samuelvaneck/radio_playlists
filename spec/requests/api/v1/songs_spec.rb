# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Songs API', type: :request do
  path '/api/v1/songs' do
    get 'List songs' do
      tags 'Songs'
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
      parameter name: :period, in: :query, type: :string, required: false,
                description: 'Time period (day, week, month, year, all)'

      response '200', 'Graph data retrieved successfully' do
        let(:song) { create(:song) }
        let(:id) { song.id }
        let(:period) { 'week' }

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
      description 'Use either period OR start_time/end_time (mutually exclusive). Returns 400 if both provided.'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Song ID'
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
        let(:song) { create(:song) }
        let!(:air_play) { create(:air_play, song: song, broadcasted_at: 1.hour.ago) }
        let(:id) { song.id }

        run_test!
      end
    end
  end

  path '/api/v1/songs/{id}/info' do
    get 'Get song Wikipedia information' do
      tags 'Songs'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Song ID'
      parameter name: :language, in: :query, type: :string, required: false,
                description: 'Wikipedia language code (en, nl, de, fr, es, it, pt, pl, ru, ja, zh). Default: en'

      response '200', 'Song info retrieved successfully' do
        schema type: :object,
               properties: {
                 info: {
                   type: :object,
                   nullable: true,
                   properties: {
                     summary: { type: :string, nullable: true },
                     content: { type: :string, nullable: true },
                     description: { type: :string, nullable: true },
                     url: { type: :string, nullable: true },
                     wikibase_item: { type: :string, nullable: true },
                     thumbnail: {
                       type: :object,
                       nullable: true,
                       properties: {
                         source: { type: :string },
                         width: { type: :integer },
                         height: { type: :integer }
                       }
                     },
                     original_image: {
                       type: :object,
                       nullable: true,
                       properties: {
                         source: { type: :string },
                         width: { type: :integer },
                         height: { type: :integer }
                       }
                     },
                     general_info: {
                       type: :object,
                       nullable: true,
                       properties: {
                         youtube_video_id: { type: :string, nullable: true },
                         publication_date: { type: :string, nullable: true },
                         genres: { type: :array, items: { type: :string }, nullable: true },
                         performers: { type: :array, items: { type: :string }, nullable: true },
                         record_labels: { type: :array, items: { type: :string }, nullable: true },
                         isrc: { type: :string, nullable: true }
                       }
                     }
                   }
                 }
               }

        let(:artist) { create(:artist, name: 'Adele') }
        let(:song) { create(:song, title: 'Rolling in the Deep', artists: [artist]) }
        let(:id) { song.id }

        before do
          allow_any_instance_of(Wikipedia::SongFinder).to receive(:get_info).and_return( # rubocop:disable RSpec/AnyInstance
            'summary' => '2010 single by Adele',
            'description' => 'Song by Adele',
            'url' => 'https://en.wikipedia.org/wiki/Rolling_in_the_Deep',
            'wikibase_item' => 'Q212764',
            'general_info' => {
              'youtube_video_id' => 'rYEDA3JcQqw',
              'publication_date' => '2010-11-29'
            }
          )
        end

        run_test!
      end

      response '404', 'Song not found' do
        let(:id) { 0 }

        run_test!
      end
    end
  end
end
