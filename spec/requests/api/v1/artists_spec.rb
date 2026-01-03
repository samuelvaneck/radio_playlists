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
        example 'application/json', :example, {
          data: [
            {
              id: '1',
              type: 'artist',
              attributes: {
                id: 1,
                name: 'Queen',
                image: 'https://i.scdn.co/image/abc123',
                id_on_spotify: '1dfeR4HaWDbWqFHLkxsg1d',
                counter: 156
              }
            }
          ],
          total_entries: 50,
          total_pages: 3,
          current_page: 1
        }

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
        example 'application/json', :example, {
          data: {
            id: '1',
            type: 'artist',
            attributes: {
              id: 1,
              name: 'Queen',
              image: 'https://i.scdn.co/image/abc123',
              id_on_spotify: '1dfeR4HaWDbWqFHLkxsg1d',
              counter: 156
            }
          }
        }

        let(:artist) { create(:artist) }
        let(:id) { artist.id }

        run_test!
      end

      response '404', 'Artist not found' do
        example 'application/json', :example, {
          status: 404,
          error: 'Not Found'
        }

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
        example 'application/json', :example, {
          labels: %w[2024-12-01 2024-12-02 2024-12-03 2024-12-04 2024-12-05],
          counts: [12, 18, 25, 14, 30]
        }

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
        example 'application/json', :example, {
          data: [
            {
              id: '1',
              type: 'song',
              attributes: {
                id: 1,
                title: 'Bohemian Rhapsody',
                spotify_artwork_url: 'https://i.scdn.co/image/abc123',
                id_on_spotify: '4u7EnebtmKWzUH433cf5Qv',
                counter: 42,
                artists: [{ id: 1, name: 'Queen' }]
              }
            },
            {
              id: '2',
              type: 'song',
              attributes: {
                id: 2,
                title: 'We Will Rock You',
                spotify_artwork_url: 'https://i.scdn.co/image/def456',
                id_on_spotify: '54flyrjcdnQdco7300avMJ',
                counter: 38,
                artists: [{ id: 1, name: 'Queen' }]
              }
            }
          ]
        }

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
        example 'application/json', :example, [
          { date: '2024-12-01', position: 3, counts: 85 },
          { date: '2024-12-02', position: 2, counts: 92 },
          { date: '2024-12-03', position: 1, counts: 110 }
        ]

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
        example 'application/json', :example, {
          peak_play_times: {
            peak_hour: 14,
            peak_day: 5,
            peak_day_name: 'Friday',
            hourly_distribution: { '8' => 12, '14' => 25, '20' => 18 },
            daily_distribution: { 'Monday' => 20, 'Friday' => 35, 'Saturday' => 28 }
          },
          play_frequency_trend: {
            trend: 'stable',
            trend_percentage: 2.1,
            weekly_counts: { '2024-01-01' => 45, '2024-01-08' => 46 },
            first_period_avg: 44.5,
            second_period_avg: 45.5
          },
          lifecycle_stats: {
            first_play: '2020-03-15T08:00:00Z',
            last_play: '2024-12-01T22:00:00Z',
            total_plays: 5420,
            days_since_first_play: 1722,
            days_since_last_play: 1,
            days_active: 1722,
            unique_days_played: 1200,
            average_plays_per_day: 3.15,
            play_consistency: 69.7
          }
        }

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
                  artists: [{ id: 1, name: 'Queen' }]
                },
                radio_station: {
                  id: 1,
                  name: 'Radio 538'
                }
              }
            }
          ],
          total_entries: 150,
          total_pages: 7,
          current_page: 1
        }

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
        example 'application/json', :example, {
          bio: {
            summary: 'Coldplay are a British rock band formed in London in 1996.',
            content: 'Coldplay are a British rock band formed in London in 1996. The band consists of vocalist and pianist Chris Martin...',
            description: 'British rock band',
            url: 'https://en.wikipedia.org/wiki/Coldplay',
            wikibase_item: 'Q45188',
            thumbnail: {
              source: 'https://upload.wikimedia.org/coldplay.jpg',
              width: 320,
              height: 240
            }
          }
        }

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
