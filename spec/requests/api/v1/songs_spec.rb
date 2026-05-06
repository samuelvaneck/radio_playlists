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
                duration_ms: 354_320,
                album_name: 'A Night at the Opera',
                lastfm_listeners: 1_200_000,
                lastfm_playcount: 5_500_000,
                lastfm_tags: %w[rock classic-rock],
                hit_potential_score: 72.45,
                hit_potential_breakdown: {
                  audio_features: 38.12,
                  artist_popularity: 16.5,
                  engagement: 10.25,
                  release_recency: 7.58,
                  audio_features_detail: {
                    loudness: 9.2, danceability: 8.5, energy: 7.1,
                    acousticness: 5.8, valence: 3.2, tempo: 2.8,
                    instrumentalness: 0.9, speechiness: 0.4, liveness: 0.2
                  }
                },
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

  path '/api/v1/songs/autocomplete' do
    get 'Autocomplete songs by search text' do
      tags 'Songs'
      produces 'application/json'
      description 'Search songs by title or artist name for autocomplete functionality'
      parameter name: :q, in: :query, type: :string, required: true,
                description: 'Search query string'
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: 'Maximum number of results (default: 10, max: 20)'

      response '200', 'Autocomplete results retrieved successfully' do
        example 'application/json', :with_results, {
          data: [
            {
              id: '1',
              type: 'song',
              attributes: {
                id: 1,
                title: 'Bohemian Rhapsody',
                spotify_artwork_url: 'https://i.scdn.co/image/abc123',
                artists: [{ id: 1, name: 'Queen' }]
              }
            },
            {
              id: '2',
              type: 'song',
              attributes: {
                id: 2,
                title: 'Bohemian Like You',
                spotify_artwork_url: 'https://i.scdn.co/image/def456',
                artists: [{ id: 2, name: 'The Dandy Warhols' }]
              }
            }
          ]
        }
        example 'application/json', :empty_results, { data: [] }

        let!(:artist) { create(:artist, name: 'Queen') }
        let!(:song) { create(:song, title: 'Bohemian Rhapsody', artists: [artist]) }
        let(:q) { 'Bohemian' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['data']).to be_an(Array)
        end
      end
    end
  end

  path '/api/v1/songs/search' do
    get 'Faceted search for songs' do
      tags 'Songs'
      produces 'application/json'
      description 'Search songs with structured filters. All filters are optional and combinable.'
      parameter name: :q, in: :query, type: :string, required: false,
                description: 'Free text search across title and artist'
      parameter name: :artist, in: :query, type: :string, required: false,
                description: 'Filter by artist name (fuzzy match)'
      parameter name: :title, in: :query, type: :string, required: false,
                description: 'Filter by song title (fuzzy match)'
      parameter name: :album, in: :query, type: :string, required: false,
                description: 'Filter by album name'
      parameter name: :year_from, in: :query, type: :integer, required: false,
                description: 'Filter songs released in or after this year'
      parameter name: :year_to, in: :query, type: :integer, required: false,
                description: 'Filter songs released in or before this year'
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: 'Maximum number of results (default: 10, max: 20)'
      parameter name: :sort_by, in: :query, type: :string, required: false,
                description: 'Sort order: popularity (default), most_played, newest'
      parameter name: :page, in: :query, type: :integer, required: false,
                description: 'Page number for pagination (24 items per page)'

      response '200', 'Search results retrieved successfully' do
        example 'application/json', :with_artist_filter, {
          data: [
            {
              id: '1',
              type: 'song',
              attributes: {
                id: 1,
                title: 'Hotline Bling',
                spotify_artwork_url: 'https://i.scdn.co/image/abc123',
                artists: [{ id: 1, name: 'Drake' }]
              }
            }
          ]
        }

        let!(:drake) { create(:artist, name: 'Drake') }
        let!(:song) { create(:song, title: 'Hotline Bling', artists: [drake], album_name: 'Views', release_date: Date.new(2016, 4, 29)) }
        let(:artist) { 'Drake' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['data']).to be_an(Array)
        end
      end

      context 'with combined filters' do
        response '200', 'Filtered results' do
          let!(:target_artist) { create(:artist, name: 'Adele') }
          let!(:target_song) do
            create(:song, title: 'Rolling in the Deep', artists: [target_artist],
                          album_name: '21', release_date: Date.new(2011, 1, 24))
          end
          let!(:other_song) { create(:song, title: 'Other Song', release_date: Date.new(2022, 1, 1)) }
          let(:artist) { 'Adele' }
          let(:year_from) { 2010 }
          let(:year_to) { 2012 }

          run_test! do |response|
            data = JSON.parse(response.body)
            titles = data['data'].map { |d| d['attributes']['title'] }
            expect(titles).to include('Rolling in the Deep')
            expect(titles).not_to include('Other Song')
          end
        end
      end

      context 'without any filters' do
        response '200', 'Returns songs ordered by popularity' do
          let!(:song) { create(:song, title: 'Some Song', popularity: 80) }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['data']).to be_an(Array)
          end
        end
      end
    end
  end

  path '/api/v1/songs/search_suggestions' do
    get 'Get search suggestions for a field' do
      tags 'Songs'
      produces 'application/json'
      description 'Returns autocomplete suggestions for a specific song search field'
      parameter name: :field, in: :query, type: :string, required: false,
                description: 'Field to suggest values for: artist, title, album, year'
      parameter name: :q, in: :query, type: :string, required: false,
                description: 'Partial input to filter suggestions'
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: 'Maximum suggestions (default: 5, max: 10)'

      response '200', 'Artist suggestions' do
        example 'application/json', :artist_suggestions, {
          suggestions: ['Drake', 'Dua Lipa'],
          field: 'artist'
        }

        let!(:artist) { create(:artist, name: 'Drake', spotify_popularity: 90) }
        let(:field) { 'artist' }
        let(:q) { 'Dra' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['suggestions']).to include('Drake')
          expect(data['field']).to eq('artist')
        end
      end

      response '200', 'Year suggestions' do
        example 'application/json', :year_suggestions, {
          suggestions: [2024, 2023, 2022],
          field: 'year'
        }

        let!(:song) { create(:song, release_date: Date.new(2023, 6, 1)) }
        let(:field) { 'year' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['suggestions']).to include(2023)
        end
      end

      response '200', 'Available fields when no field specified' do
        example 'application/json', :available_fields, {
          suggestions: %w[artist title album year_from year_to],
          field: nil
        }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['suggestions']).to eq(%w[artist title album year_from year_to])
        end
      end
    end
  end

  path '/api/v1/songs/{id}' do
    get 'Get a song' do
      tags 'Songs'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, required: true, description: 'Song ID or slug'

      response '200', 'Song retrieved successfully by ID' do
        example 'application/json', :example, {
          data: {
            id: '1',
            type: 'song',
            attributes: {
              id: 1,
              title: 'Bohemian Rhapsody',
              slug: 'bohemian-rhapsody-queen',
              spotify_artwork_url: 'https://i.scdn.co/image/abc123',
              id_on_spotify: '4u7EnebtmKWzUH433cf5Qv',
              duration_ms: 354_320,
              album_name: 'A Night at the Opera',
              lastfm_listeners: 1_200_000,
              lastfm_playcount: 5_500_000,
              lastfm_tags: %w[rock classic-rock],
              hit_potential_score: 72.45,
              hit_potential_breakdown: {
                audio_features: 38.12,
                artist_popularity: 16.5,
                engagement: 10.25,
                release_recency: 7.58,
                audio_features_detail: {
                  loudness: 9.2, danceability: 8.5, energy: 7.1,
                  acousticness: 5.8, valence: 3.2, tempo: 2.8,
                  instrumentalness: 0.9, speechiness: 0.4, liveness: 0.2
                }
              },
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

      response '200', 'Song retrieved successfully by slug' do
        let(:song) { create(:song) }
        let(:id) { song.slug }

        run_test!
      end

      response '404', 'Song not found' do
        example 'application/json', :example, {
          status: 404,
          error: 'Not Found'
        }

        let(:id) { 'non-existent-slug' }

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
          },
          lifecycle_phase: {
            phase: 'peak',
            days_to_peak: 42,
            weeks_since_first_play: 8,
            peak_week: '2024-11-18',
            peak_count: 25,
            current_weekly_average: 22.5,
            weekly_counts: {
              '2024-10-07': 5, '2024-10-14': 12, '2024-10-21': 18,
              '2024-10-28': 22, '2024-11-04': 25, '2024-11-11': 24,
              '2024-11-18': 25, '2024-11-25': 21
            }
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

        before do # rubocop:disable RSpec/ScatteredSetup
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

        run_test! do
          expect(song.reload.wikipedia_url).to eq('https://en.wikipedia.org/wiki/Rolling_in_the_Deep')
        end
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

  path '/api/v1/songs/{id}/widget' do
    get 'Get song widget data' do
      tags 'Songs'
      produces 'application/json'
      description 'Returns widget data for a song including total plays, number of radio stations, release date, and duration.'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Song ID'

      response '200', 'Widget data retrieved successfully' do
        example 'application/json', :example, {
          total_played: 1250,
          radio_stations_count: 8,
          release_date: '2026-01-09',
          duration_ms: 212_000
        }

        let(:radio_station) { create(:radio_station) }
        let(:song) { create(:song, release_date: '2026-01-09', duration_ms: 212_000) }
        let!(:air_play) { create(:air_play, song: song, radio_station: radio_station) }
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

  path '/api/v1/songs/natural_language_search' do
    get 'Natural language search for songs' do
      tags 'Songs'
      produces 'application/json'
      description 'Translates a natural language query into structured filters using an LLM and returns matching songs.'
      parameter name: :q, in: :query, type: :string, required: true,
                description: 'Natural language query (e.g. "upbeat Dutch songs played on Radio 538 last week")'
      parameter name: :page, in: :query, type: :integer, required: false,
                description: 'Page number for pagination (24 items per page)'

      response '200', 'Search results retrieved successfully' do
        let(:radio_station) { create(:radio_station, name: 'Test Station NLS') }
        let(:artist) { create(:artist, name: 'Test Artist NLS', country_of_origin: ['NL']) }
        let(:song) { create(:song, title: 'Test Song NLS', artists: [artist], popularity: 50) }
        let(:q) { 'Dutch songs from last week' }
        let(:translator) { instance_double(Llm::QueryTranslator, translate: { country: 'NL', period: 'week' }) }

        before do # rubocop:disable RSpec/ScatteredSetup
          create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 2.days.ago, status: :confirmed)
          allow(Llm::QueryTranslator).to receive(:new).and_return(translator)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('data')
          expect(data).to have_key('filters')
          expect(data).to have_key('query')
          expect(data).to have_key('total_entries')
          expect(data).to have_key('total_pages')
          expect(data).to have_key('current_page')
        end
      end

      response '400', 'Missing query parameter' do
        let(:q) { '' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Query parameter q is required')
        end
      end
    end
  end
end
