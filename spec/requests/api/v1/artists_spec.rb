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
                genres: %w[rock classic-rock],
                spotify_popularity: 85,
                spotify_followers_count: 42_000_000,
                country_of_origin: ['United Kingdom'],
                lastfm_listeners: 5_800_000,
                lastfm_playcount: 200_000_000,
                lastfm_tags: %w[rock classic-rock british],
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

  path '/api/v1/artists/autocomplete' do
    get 'Autocomplete artists by name' do
      tags 'Artists'
      produces 'application/json'
      description 'Search artists by name for autocomplete functionality'
      parameter name: :q, in: :query, type: :string, required: true,
                description: 'Search query string'
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: 'Maximum number of results (default: 10, max: 20)'

      response '200', 'Autocomplete results retrieved successfully' do
        example 'application/json', :with_results, {
          data: [
            {
              id: '1',
              type: 'artist',
              attributes: {
                id: 1,
                name: 'Queen',
                spotify_artwork_url: 'https://i.scdn.co/image/abc123'
              }
            },
            {
              id: '2',
              type: 'artist',
              attributes: {
                id: 2,
                name: 'Queens of the Stone Age',
                spotify_artwork_url: 'https://i.scdn.co/image/def456'
              }
            }
          ]
        }
        example 'application/json', :empty_results, { data: [] }

        let!(:artist) { create(:artist, name: 'Queen') }
        let(:q) { 'Queen' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['data']).to be_an(Array)
        end
      end
    end
  end

  path '/api/v1/artists/search' do
    get 'Faceted search for artists' do
      tags 'Artists'
      produces 'application/json'
      description 'Search artists with structured filters. All filters are optional and combinable.'
      parameter name: :q, in: :query, type: :string, required: false,
                description: 'Free text search on artist name'
      parameter name: :name, in: :query, type: :string, required: false,
                description: 'Filter by artist name (fuzzy match)'
      parameter name: :genre, in: :query, type: :string, required: false,
                description: 'Filter by genre'
      parameter name: :country, in: :query, type: :string, required: false,
                description: 'Filter by country of origin'
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: 'Maximum number of results (default: 10, max: 20)'
      parameter name: :sort_by, in: :query, type: :string, required: false,
                description: 'Sort order: popularity (default), most_played'
      parameter name: :page, in: :query, type: :integer, required: false,
                description: 'Page number for pagination (24 items per page)'

      response '200', 'Search results retrieved successfully' do
        example 'application/json', :with_genre_filter, {
          data: [
            {
              id: '1',
              type: 'artist',
              attributes: {
                id: 1,
                name: 'Coldplay',
                genres: %w[rock pop],
                country_of_origin: ['United Kingdom']
              }
            }
          ]
        }

        let!(:rock_artist) { create(:artist, name: 'Coldplay', genres: %w[rock pop], spotify_popularity: 90) }
        let!(:hiphop_artist) { create(:artist, name: 'Drake', genres: %w[hip-hop rap], spotify_popularity: 95) }
        let(:genre) { 'rock' }

        run_test! do |response|
          data = JSON.parse(response.body)
          names = data['data'].map { |d| d['attributes']['name'] }
          expect(names).to include('Coldplay')
          expect(names).not_to include('Drake')
        end
      end

      context 'with country filter' do
        response '200', 'Filtered by country' do
          let!(:dutch_artist) { create(:artist, name: 'Davina Michelle', country_of_origin: ['Netherlands']) }
          let!(:american_artist) { create(:artist, name: 'Taylor Swift', country_of_origin: ['United States']) }
          let(:country) { 'Netherlands' }

          run_test! do |response|
            data = JSON.parse(response.body)
            names = data['data'].map { |d| d['attributes']['name'] }
            expect(names).to include('Davina Michelle')
            expect(names).not_to include('Taylor Swift')
          end
        end
      end

      context 'without any filters' do
        response '200', 'Returns artists ordered by popularity' do
          let!(:artist) { create(:artist, spotify_popularity: 80) }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['data']).to be_an(Array)
          end
        end
      end
    end
  end

  path '/api/v1/artists/search_suggestions' do
    get 'Get search suggestions for a field' do
      tags 'Artists'
      produces 'application/json'
      description 'Returns autocomplete suggestions for a specific artist search field'
      parameter name: :field, in: :query, type: :string, required: false,
                description: 'Field to suggest values for: name, genre, country'
      parameter name: :q, in: :query, type: :string, required: false,
                description: 'Partial input to filter suggestions'
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: 'Maximum suggestions (default: 5, max: 10)'

      response '200', 'Genre suggestions' do
        example 'application/json', :genre_suggestions, {
          suggestions: %w[rock pop hip-hop],
          field: 'genre'
        }

        let!(:artist) { create(:artist, genres: %w[rock pop]) }
        let(:field) { 'genre' }
        let(:q) { 'ro' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['suggestions']).to include('rock')
          expect(data['field']).to eq('genre')
        end
      end

      response '200', 'Available fields when no field specified' do
        example 'application/json', :available_fields, {
          suggestions: %w[name genre country],
          field: nil
        }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['suggestions']).to eq(%w[name genre country])
        end
      end
    end
  end

  path '/api/v1/artists/{id}' do
    get 'Get an artist' do
      tags 'Artists'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, required: true, description: 'Artist ID or slug'

      response '200', 'Artist retrieved successfully by ID' do
        example 'application/json', :example, {
          data: {
            id: '1',
            type: 'artist',
            attributes: {
              id: 1,
              name: 'Queen',
              slug: 'queen',
              image: 'https://i.scdn.co/image/abc123',
              id_on_spotify: '1dfeR4HaWDbWqFHLkxsg1d',
              genres: %w[rock classic-rock],
              spotify_popularity: 85,
              spotify_followers_count: 42_000_000,
              country_of_origin: ['United Kingdom'],
              lastfm_listeners: 5_800_000,
              lastfm_playcount: 200_000_000,
              lastfm_tags: %w[rock classic-rock british],
              counter: 156
            }
          }
        }

        let(:artist) { create(:artist) }
        let(:id) { artist.id }

        run_test!
      end

      response '200', 'Artist retrieved successfully by slug' do
        let(:artist) { create(:artist) }
        let(:id) { artist.slug }

        run_test!
      end

      response '404', 'Artist not found' do
        example 'application/json', :example, {
          status: 404,
          error: 'Not Found'
        }

        let(:id) { 'non-existent-slug' }

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
                album_name: 'A Night at the Opera',
                lastfm_listeners: 1_200_000,
                lastfm_playcount: 5_500_000,
                lastfm_tags: %w[rock classic-rock],
                counter: 42,
                artists: [{ id: 1, name: 'Queen', country_of_origin: ['United Kingdom'] }]
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
                album_name: 'News of the World',
                lastfm_listeners: 980_000,
                lastfm_playcount: 4_200_000,
                lastfm_tags: %w[rock classic-rock],
                counter: 38,
                artists: [{ id: 1, name: 'Queen', country_of_origin: ['United Kingdom'] }]
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

  path '/api/v1/artists/{id}/similar_artists' do
    get 'Get similar artists' do
      tags 'Artists'
      produces 'application/json'
      description 'Returns artists with the most overlapping genres and Last.fm tags, using Spotify popularity as tiebreaker'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Artist ID'
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: 'Maximum number of results (default: 10, max: 20)'

      response '200', 'Similar artists retrieved successfully' do
        example 'application/json', :example, {
          data: [
            {
              id: '2',
              type: 'artist',
              attributes: {
                id: 2,
                name: 'Oasis',
                genres: %w[rock britpop],
                lastfm_tags: %w[rock britpop british],
                spotify_popularity: 80
              }
            }
          ]
        }

        let(:artist) do
          create(:artist, name: 'Coldplay', genres: %w[rock pop britpop], lastfm_tags: %w[rock british alternative])
        end
        let!(:similar) do
          create(:artist, name: 'Oasis', genres: %w[rock britpop], lastfm_tags: %w[rock britpop british],
                          spotify_popularity: 80)
        end
        let!(:different) { create(:artist, name: 'Eminem', genres: %w[hip-hop rap], lastfm_tags: %w[rap hip-hop]) }
        let!(:partial_match) do
          create(:artist, name: 'U2', genres: %w[rock], lastfm_tags: %w[irish rock], spotify_popularity: 75)
        end
        let(:id) { artist.id }

        run_test! do |response|
          data = JSON.parse(response.body)['data']
          expect(data.first['attributes']['name']).to eq('Oasis')
        end
      end

      response '200', 'No similar artists when artist has no genres or tags' do
        let(:artist) { create(:artist, name: 'Unknown', genres: [], lastfm_tags: []) }
        let(:id) { artist.id }

        run_test! do |response|
          data = JSON.parse(response.body)['data']
          expect(data).to eq([])
        end
      end
    end
  end

  path '/api/v1/artists/{id}/widget' do
    get 'Get artist widget data' do
      tags 'Artists'
      produces 'application/json'
      description 'Returns widget data for an artist including total plays, total songs, number of radio stations, and country of origin.'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Artist ID'

      response '200', 'Widget data retrieved successfully' do
        example 'application/json', :example, {
          total_played: 5420,
          total_songs: 25,
          radio_stations_count: 12,
          country_of_origin: ['United States']
        }

        let(:artist) { create(:artist, country_of_origin: ['United States']) }
        let!(:song) { create(:song, artists: [artist]) }
        let!(:air_play) { create(:air_play, song: song) }
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

        before do # rubocop:disable RSpec/ScatteredSetup
          allow_any_instance_of(Wikipedia::ArtistFinder).to receive(:get_info).and_return({ # rubocop:disable RSpec/AnyInstance
                                                                                            'summary' => 'British rock band',
                                                                                            'description' => 'British rock band',
                                                                                            'url' => 'https://en.wikipedia.org/wiki/Coldplay'
                                                                                          })
        end

        run_test! do
          expect(artist.reload.wikipedia_url).to eq('https://en.wikipedia.org/wiki/Coldplay')
        end
      end
    end
  end

  path '/api/v1/artists/natural_language_search' do
    get 'Natural language search for artists' do
      tags 'Artists'
      produces 'application/json'
      description 'Translates a natural language query into structured filters using an LLM and returns matching artists.'
      parameter name: :q, in: :query, type: :string, required: true,
                description: 'Natural language query (e.g. "Dutch pop artists played on NPO Radio 2")'
      parameter name: :page, in: :query, type: :integer, required: false,
                description: 'Page number for pagination (24 items per page)'

      response '200', 'Search results retrieved successfully' do
        let(:radio_station) { create(:radio_station, name: 'Test Station NLS Artists') }
        let(:artist) { create(:artist, name: 'Test Artist NLS Artists', country_of_origin: ['NL'], genres: ['pop']) }
        let(:song) { create(:song, title: 'Test Song NLS Artists', artists: [artist]) }
        let(:q) { 'Dutch pop artists' }
        let(:translator) do
          instance_double(Llm::QueryTranslator,
                          translate: { search_type: 'artists', country: 'NL', genre: 'pop', period: 'month' })
        end

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
