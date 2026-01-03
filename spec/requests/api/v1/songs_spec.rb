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
      parameter name: :danceability_min, in: :query, type: :number, required: false,
                description: 'Minimum danceability (0.0 - 1.0)'
      parameter name: :danceability_max, in: :query, type: :number, required: false,
                description: 'Maximum danceability (0.0 - 1.0)'
      parameter name: :energy_min, in: :query, type: :number, required: false,
                description: 'Minimum energy (0.0 - 1.0)'
      parameter name: :energy_max, in: :query, type: :number, required: false,
                description: 'Maximum energy (0.0 - 1.0)'
      parameter name: :speechiness_min, in: :query, type: :number, required: false,
                description: 'Minimum speechiness (0.0 - 1.0)'
      parameter name: :speechiness_max, in: :query, type: :number, required: false,
                description: 'Maximum speechiness (0.0 - 1.0)'
      parameter name: :acousticness_min, in: :query, type: :number, required: false,
                description: 'Minimum acousticness (0.0 - 1.0)'
      parameter name: :acousticness_max, in: :query, type: :number, required: false,
                description: 'Maximum acousticness (0.0 - 1.0)'
      parameter name: :instrumentalness_min, in: :query, type: :number, required: false,
                description: 'Minimum instrumentalness (0.0 - 1.0)'
      parameter name: :instrumentalness_max, in: :query, type: :number, required: false,
                description: 'Maximum instrumentalness (0.0 - 1.0)'
      parameter name: :liveness_min, in: :query, type: :number, required: false,
                description: 'Minimum liveness (0.0 - 1.0)'
      parameter name: :liveness_max, in: :query, type: :number, required: false,
                description: 'Maximum liveness (0.0 - 1.0)'
      parameter name: :valence_min, in: :query, type: :number, required: false,
                description: 'Minimum valence/mood (0.0 - 1.0)'
      parameter name: :valence_max, in: :query, type: :number, required: false,
                description: 'Maximum valence/mood (0.0 - 1.0)'
      parameter name: :tempo_min, in: :query, type: :number, required: false,
                description: 'Minimum tempo in BPM'
      parameter name: :tempo_max, in: :query, type: :number, required: false,
                description: 'Maximum tempo in BPM'

      response '200', 'Songs retrieved successfully' do
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
                artists: [{ id: 1, name: 'Queen' }],
                music_profile: {
                  danceability: 0.39,
                  energy: 0.40,
                  speechiness: 0.05,
                  acousticness: 0.29,
                  instrumentalness: 0.0,
                  liveness: 0.24,
                  valence: 0.22,
                  tempo: 71.17
                }
              }
            }
          ],
          total_entries: 100,
          total_pages: 5,
          current_page: 1
        }

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
        example 'application/json', :example, {
          data: {
            id: '1',
            type: 'song',
            attributes: {
              id: 1,
              title: 'Bohemian Rhapsody',
              spotify_artwork_url: 'https://i.scdn.co/image/abc123',
              id_on_spotify: '4u7EnebtmKWzUH433cf5Qv',
              counter: 42,
              artists: [{ id: 1, name: 'Queen' }],
              music_profile: {
                danceability: 0.39,
                energy: 0.40,
                speechiness: 0.05,
                acousticness: 0.29,
                instrumentalness: 0.0,
                liveness: 0.24,
                valence: 0.22,
                tempo: 71.17
              }
            }
          }
        }

        let(:song) { create(:song) }
        let(:id) { song.id }

        run_test!
      end

      response '404', 'Song not found' do
        example 'application/json', :example, {
          status: 404,
          error: 'Not Found'
        }

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
        example 'application/json', :example, {
          labels: %w[2024-12-01 2024-12-02 2024-12-03 2024-12-04 2024-12-05],
          counts: [5, 8, 12, 7, 15]
        }

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
        example 'application/json', :example, [
          { date: '2024-12-01', position: 5, counts: 42 },
          { date: '2024-12-02', position: 3, counts: 58 },
          { date: '2024-12-03', position: 1, counts: 75 }
        ]

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
        example 'application/json', :example, {
          peak_play_times: {
            peak_hour: 8,
            peak_day: 1,
            peak_day_name: 'Monday',
            hourly_distribution: { '8' => 5, '14' => 3, '20' => 7 },
            daily_distribution: { 'Monday' => 10, 'Tuesday' => 8, 'Wednesday' => 12 }
          },
          play_frequency_trend: {
            trend: 'rising',
            trend_percentage: 25.5,
            weekly_counts: { '2024-01-01' => 5, '2024-01-08' => 7 },
            first_period_avg: 4.0,
            second_period_avg: 5.0
          },
          lifecycle_stats: {
            first_play: '2024-01-01T10:00:00Z',
            last_play: '2024-12-01T15:00:00Z',
            total_plays: 150,
            days_since_first_play: 335,
            days_since_last_play: 7,
            days_active: 335,
            unique_days_played: 120,
            average_plays_per_day: 0.45,
            play_consistency: 35.8
          }
        }

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
          total_entries: 50,
          total_pages: 3,
          current_page: 1
        }

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
        example 'application/json', :example, {
          info: {
            summary: '2010 single by Adele from the album 21',
            content: 'Rolling in the Deep is a song recorded by English singer Adele...',
            description: '2010 single by Adele',
            url: 'https://en.wikipedia.org/wiki/Rolling_in_the_Deep',
            wikibase_item: 'Q212764',
            thumbnail: {
              source: 'https://upload.wikimedia.org/image.jpg',
              width: 320,
              height: 213
            },
            original_image: {
              source: 'https://upload.wikimedia.org/original.jpg',
              width: 4272,
              height: 2848
            },
            general_info: {
              youtube_video_id: 'rYEDA3JcQqw',
              publication_date: '2010-11-29',
              genres: %w[soul pop],
              performers: ['Adele'],
              record_labels: ['XL Recordings']
            }
          }
        }

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
        example 'application/json', :example, {
          status: 404,
          error: 'Not Found'
        }

        let(:id) { 0 }

        run_test!
      end
    end
  end

  path '/api/v1/songs/{id}/music_profile' do
    get 'Get song music profile (Spotify audio features)' do
      tags 'Songs'
      produces 'application/json'
      description 'Returns Spotify audio features for the song with attribute descriptions in metadata'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Song ID'

      response '200', 'Music profile retrieved successfully' do
        example 'application/json', :example, {
          data: {
            id: '1',
            type: 'music_profile',
            attributes: {
              id: 1,
              danceability: 0.65,
              energy: 0.72,
              speechiness: 0.08,
              acousticness: 0.25,
              instrumentalness: 0.02,
              liveness: 0.12,
              valence: 0.58,
              tempo: 120.5
            }
          },
          meta: {
            attribute_descriptions: {
              danceability: {
                name: 'Danceability',
                description: 'Describes how suitable a track is for dancing based on tempo, rhythm stability, beat strength, and overall regularity.',
                range: '0.0 to 1.0',
                high_threshold: 0.5
              },
              energy: {
                name: 'Energy',
                description: 'Represents intensity and activity. Energetic tracks feel fast, loud, and noisy.',
                range: '0.0 to 1.0',
                high_threshold: 0.5
              },
              tempo: {
                name: 'Tempo',
                description: 'The overall estimated tempo of a track in beats per minute (BPM).',
                range: '0 to 250 BPM'
              }
            }
          }
        }

        let(:song) { create(:song) }
        let!(:music_profile) { create(:music_profile, song: song) }
        let(:id) { song.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['data']).to be_present
          expect(data['data']['attributes']).to include('danceability', 'energy', 'tempo')
          expect(data['meta']['attribute_descriptions']).to be_present
        end
      end

      response '200', 'Song has no music profile' do
        example 'application/json', :example, {
          data: nil,
          meta: {
            attribute_descriptions: {
              danceability: {
                name: 'Danceability',
                description: 'Describes how suitable a track is for dancing.',
                range: '0.0 to 1.0',
                high_threshold: 0.5
              }
            }
          }
        }

        let(:song) { create(:song) }
        let(:id) { song.id }

        run_test!
      end

      response '404', 'Song not found' do
        example 'application/json', :example, {
          status: 404,
          error: 'Not Found'
        }

        let(:id) { 0 }

        run_test!
      end
    end
  end
end
