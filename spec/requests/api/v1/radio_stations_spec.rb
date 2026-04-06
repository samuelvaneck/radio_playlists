# frozen_string_literal: true

require 'swagger_helper'

describe 'RadioStations API', type: :request do
  path '/api/v1/radio_stations' do
    get 'List all radio stations' do
      tags 'Radio Stations'
      produces 'application/json'

      response '200', 'Radio stations retrieved successfully' do
        example 'application/json', :example, {
          data: [
            {
              id: '1',
              type: 'radio_station',
              attributes: {
                id: 1,
                name: 'Radio 538',
                slug: 'radio-538',
                url: 'https://www.538.nl',
                country_code: 'NL'
              }
            },
            {
              id: '2',
              type: 'radio_station',
              attributes: {
                id: 2,
                name: 'Qmusic',
                slug: 'qmusic',
                url: 'https://www.qmusic.nl',
                country_code: 'NL'
              }
            }
          ]
        }

        let!(:radio_station) { create(:radio_station) }

        run_test!
      end
    end
  end

  path '/api/v1/radio_stations/{id}' do
    get 'Get a radio station' do
      tags 'Radio Stations'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, required: true, description: 'Radio station ID or slug'

      response '200', 'Radio station retrieved successfully by ID' do
        example 'application/json', :example, {
          data: {
            id: '1',
            type: 'radio_station',
            attributes: {
              id: 1,
              name: 'Radio 538',
              slug: 'radio-538',
              url: 'https://www.538.nl',
              country_code: 'NL'
            }
          }
        }

        let(:radio_station) { create(:radio_station) }
        let(:id) { radio_station.id }

        run_test!
      end

      response '200', 'Radio station retrieved successfully by slug' do
        let(:radio_station) { create(:radio_station) }
        let(:id) { radio_station.slug }

        run_test!
      end

      response '404', 'Radio station not found' do
        example 'application/json', :example, {
          status: 404,
          error: 'Not Found'
        }

        let(:id) { 'non-existent-slug' }

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
        example 'application/json', :example, {
          status: 'online',
          last_air_play: '2024-12-01T14:30:00Z',
          song_count_today: 245,
          stream_available: true
        }

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
        example 'application/json', :example, {
          data: {
            id: 1,
            name: 'Radio 538',
            total_air_plays: 125_000,
            unique_songs: 8500,
            unique_artists: 3200,
            top_songs: [
              { id: 1, title: 'Bohemian Rhapsody', count: 150 },
              { id: 2, title: 'Blinding Lights', count: 142 }
            ],
            top_artists: [
              { id: 1, name: 'Queen', count: 520 },
              { id: 2, name: 'The Weeknd', count: 485 }
            ]
          }
        }

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
        example 'application/json', :example, {
          data: [
            {
              day_part: 'morning',
              danceability_average: 0.65,
              energy_average: 0.72,
              valence_average: 0.58,
              tempo: 118.5,
              counter: 450,
              high_danceability_percentage: 0.72,
              high_energy_percentage: 0.68
            },
            {
              day_part: 'afternoon',
              danceability_average: 0.70,
              energy_average: 0.75,
              valence_average: 0.62,
              tempo: 122.3,
              counter: 380,
              high_danceability_percentage: 0.78,
              high_energy_percentage: 0.74
            }
          ],
          meta: {
            attribute_descriptions: {
              danceability_average: {
                name: 'Danceability Average',
                description: 'Average danceability score for tracks played during this time period.',
                range: '0.0 to 1.0'
              }
            }
          }
        }

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
        example 'application/json', :example, {
          data: [
            {
              id: 1,
              name: 'Radio 538',
              slug: 'radio-538',
              country_code: 'NL',
              is_currently_playing: true,
              last_played_song: {
                id: 1,
                title: 'Bohemian Rhapsody',
                artists: [{ id: 1, name: 'Queen' }],
                broadcasted_at: '2024-12-01T14:30:00Z'
              }
            },
            {
              id: 2,
              name: 'Qmusic',
              slug: 'qmusic',
              country_code: 'NL',
              is_currently_playing: false,
              last_played_song: {
                id: 2,
                title: 'Blinding Lights',
                artists: [{ id: 2, name: 'The Weeknd' }],
                broadcasted_at: '2024-12-01T14:28:00Z'
              }
            }
          ]
        }

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
        example 'application/json', :example, {
          data: [
            {
              id: '1',
              type: 'song',
              attributes: {
                id: 1,
                title: 'New Release Song',
                spotify_artwork_url: 'https://i.scdn.co/image/new123',
                artists: [{ id: 1, name: 'New Artist' }],
                first_broadcasted_at: '2024-12-01T10:00:00Z',
                radio_station: {
                  id: 1,
                  name: 'Radio 538'
                }
              }
            }
          ],
          total_entries: 25,
          total_pages: 2,
          current_page: 1
        }

        let(:period) { 'week' }
        let!(:radio_station) { create(:radio_station) }

        run_test!
      end

      response '400', 'Period or start_time parameter is required' do
        example 'application/json', :example, {
          error: 'Period or start_time parameter is required'
        }

        let(:period) { nil }

        run_test!
      end
    end
  end

  path '/api/v1/radio_stations/release_date_graph' do
    get 'Get release date distribution of played songs' do
      tags 'Radio Stations'
      produces 'application/json'
      description 'Returns number of unique songs played grouped by release year. ' \
                  'Use either period OR start_time/end_time (mutually exclusive). Returns 400 if neither provided.'
      parameter name: :period, in: :query, type: :string, required: false,
                description: 'Granular time period: 1_day, 3_days, 1_week, 2_weeks, 4_weeks, ' \
                             '1_month, 6_months, 1_year, all. Mutually exclusive with start_time/end_time'
      parameter name: :start_time, in: :query, type: :string, required: false,
                description: 'Custom start time (YYYY-MM-DDTHH:MM). Mutually exclusive with period'
      parameter name: :end_time, in: :query, type: :string, required: false,
                description: 'Custom end time (YYYY-MM-DDTHH:MM). Defaults to current time'
      parameter name: 'radio_station_ids[]', in: :query, type: :array, items: { type: :integer },
                required: false, description: 'Filter by radio station IDs'

      response '200', 'Release date graph data retrieved successfully' do
        example 'application/json', :example, [
          { year: 2020, 'Radio 538': 10, 'Qmusic': 5 },
          { year: 2023, 'Radio 538': 25, 'Qmusic': 18 },
          { columns: ['Radio 538', 'Qmusic'] }
        ]

        let(:radio_station) { create(:radio_station) }
        let(:song) { create(:song, release_date: Date.new(2023, 6, 15)) }
        let!(:air_play) { create(:air_play, radio_station: radio_station, song: song, broadcasted_at: 1.day.ago) }
        let(:period) { '1_year' }

        run_test!
      end

      response '400', 'Period or start_time parameter is required' do
        example 'application/json', :example, {
          error: 'Period or start_time parameter is required'
        }

        let(:period) { nil }

        run_test!
      end
    end
  end

  path '/api/v1/radio_stations/{id}/widget' do
    get 'Get radio station widget data' do
      tags 'Radio Stations'
      produces 'application/json'
      description 'Returns widget data for a radio station including top track, top artist, ' \
                  'and number of new songs for the past week, and number of songs played for the past day.'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Radio station ID'

      response '200', 'Widget data retrieved successfully' do
        example 'application/json', :example, {
          top_song: {
            data: {
              id: '1',
              type: 'song',
              attributes: {
                id: 1,
                title: 'Bohemian Rhapsody',
                spotify_artwork_url: 'https://i.scdn.co/image/abc123',
                artists: [{ data: { id: '1', type: 'artist', attributes: { id: 1, name: 'Queen' } } }],
                counter: 42
              }
            }
          },
          top_artist: {
            data: {
              id: '1',
              type: 'artist',
              attributes: {
                id: 1,
                name: 'Queen',
                counter: 85
              }
            }
          },
          songs_played_count: 1250,
          new_songs_count: 15
        }

        let(:radio_station) { create(:radio_station) }
        let(:id) { radio_station.id }

        run_test!
      end

      response '404', 'Radio station not found' do
        example 'application/json', :example, {
          status: 404,
          error: 'Not Found'
        }

        let(:id) { 0 }

        run_test!
      end
    end
  end

  path '/api/v1/radio_stations/{id}/sound_profile' do
    get 'Get radio station sound profile' do
      tags 'Radio Stations'
      produces 'application/json'
      description 'Returns a dynamic sound profile for a radio station based on audio features, genres, tags, ' \
                  'and release date distribution of played songs.'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Radio station ID'
      parameter name: :start_time, in: :query, type: :string, required: false,
                description: 'Custom start time (YYYY-MM-DDTHH:MM). Defaults to 4 weeks ago'
      parameter name: :end_time, in: :query, type: :string, required: false,
                description: 'Custom end time (YYYY-MM-DDTHH:MM). Defaults to current time'

      response '200', 'Sound profile retrieved successfully' do
        example 'application/json', :example, {
          data: {
            radio_station: { id: 1, name: 'Radio 538', slug: 'radio-538' },
            period: { start_time: '2026-01-01T00:00:00Z', end_time: '2026-02-01T00:00:00Z' },
            audio_features: {
              danceability: { average: 0.7, label: 'very danceable' },
              energy: { average: 0.65, label: 'high-energy' }
            },
            tempo: { average: 120.5, label: 'upbeat' },
            top_genres: [{ name: 'pop', count: 150 }, { name: 'dance', count: 120 }],
            top_tags: [{ name: 'electronic', count: 200 }],
            release_decade_distribution: [{ decade: '2020s', count: 500 }],
            release_year_range: {
              from: 2015, to: 2025, median_year: 2020, peak_decades: [2010, 2020],
              era_description_en: 'primarily from the 2010s and 2020s',
              era_description_nl: 'voornamelijk uit de jaren 2010 en 2020',
              total_songs_with_date: 800
            },
            description_en: 'Radio 538 is a high-energy, upbeat and positive station playing very danceable, upbeat music.',
            description_nl: 'Radio 538 is een energiek, vrolijk en positief station met zeer dansbare, vlotte muziek.',
            sample_size: 1000
          }
        }

        let(:radio_station) { create(:radio_station) }
        let(:id) { radio_station.id }

        run_test!
      end

      response '404', 'Radio station not found' do
        example 'application/json', :example, {
          status: 404,
          error: 'Not Found'
        }

        let(:id) { 0 }

        run_test!
      end
    end
  end

  path '/api/v1/radio_stations/{id}/diversity_metrics' do
    get 'Get playlist diversity metrics for a radio station' do
      tags 'Radio Stations'
      produces 'application/json'
      description 'Calculates playlist diversity indices (Gini coefficient, Shannon entropy, HHI) ' \
                  'measuring how concentrated or diverse a station\'s airplay distribution is. ' \
                  'Based on Stirling (2007) diversity framework and ACM (2023) recommendation diversity research.'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Radio station ID'
      parameter name: :start_time, in: :query, type: :string, required: false,
                description: 'Custom start time (YYYY-MM-DDTHH:MM). Defaults to 4 weeks ago'
      parameter name: :end_time, in: :query, type: :string, required: false,
                description: 'Custom end time (YYYY-MM-DDTHH:MM). Defaults to current time'

      response '200', 'Diversity metrics retrieved successfully' do
        example 'application/json', :example, {
          data: {
            radio_station: { id: 1, name: 'Radio 538', slug: 'radio-538' },
            period: { start_time: '2026-03-01T00:00:00Z', end_time: '2026-04-01T00:00:00Z' },
            metrics: {
              gini_coefficient: 0.72,
              shannon_entropy: 3.45,
              normalized_entropy: 0.68,
              hhi: 1250.0,
              label: 'moderately diverse'
            },
            sample: { unique_songs: 450, total_plays: 8500 },
            top_songs: [
              { song_id: 1, title: 'Popular Song', artists: ['Artist Name'], play_count: 85, share: 1.0 },
              { song_id: 2, title: 'Another Hit', artists: ['Other Artist'], play_count: 72, share: 0.85 }
            ]
          }
        }

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

  path '/api/v1/radio_stations/{id}/exposure_saturation' do
    get 'Get exposure saturation analysis for a radio station' do
      tags 'Radio Stations'
      produces 'application/json'
      description 'Analyzes song exposure levels based on the mere exposure effect (Zajonc 1968). ' \
                  'Calculates where each song sits on the inverted-U preference curve — ' \
                  'optimal exposure increases liking, but overexposure leads to listener fatigue. ' \
                  'Based on Chmiel & Schubert (2017) research on music preference and repeated exposure.'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Radio station ID'
      parameter name: :start_time, in: :query, type: :string, required: false,
                description: 'Custom start time (YYYY-MM-DDTHH:MM). Defaults to 1 week ago'
      parameter name: :end_time, in: :query, type: :string, required: false,
                description: 'Custom end time (YYYY-MM-DDTHH:MM). Defaults to current time'

      response '200', 'Exposure saturation data retrieved successfully' do
        example 'application/json', :example, {
          data: {
            radio_station: { id: 1, name: 'Radio 538', slug: 'radio-538' },
            period: { start_time: '2026-03-25T00:00:00Z', end_time: '2026-04-01T00:00:00Z' },
            baseline: {
              median_plays: 5, mean_plays: 8.2, std_deviation: 12.3,
              total_songs: 320, total_plays: 2624
            },
            songs: [
              {
                song_id: 1, title: 'Overplayed Hit', artists: ['Artist'],
                play_count: 45, plays_per_day: 6.43, exposure_ratio: 9.0,
                saturation_index: 0.002, status: 'heavily_overexposed'
              },
              {
                song_id: 2, title: 'Well Balanced', artists: ['Other Artist'],
                play_count: 8, plays_per_day: 1.14, exposure_ratio: 1.6,
                saturation_index: 0.995, status: 'optimal'
              }
            ],
            overexposed_count: 5,
            underexposed_count: 12
          }
        }

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

  path '/api/v1/radio_stations/seasonal_audio_trends' do
    get 'Get seasonal audio feature trends' do
      tags 'Radio Stations'
      produces 'application/json'
      description 'Aggregates audio features (valence, energy, danceability, tempo) by month per station. ' \
                  'Research shows seasonal patterns: valence peaks in June/July, summer hits cluster ' \
                  'around 118 BPM with high energy. Based on Park et al. (2019) global streaming patterns research.'
      parameter name: 'radio_station_ids[]', in: :query, type: :array, items: { type: :integer },
                required: false, description: 'Filter by radio station IDs. Omit for all stations'
      parameter name: :start_time, in: :query, type: :string, required: false,
                description: 'Custom start time (YYYY-MM-DDTHH:MM). Defaults to 1 year ago'
      parameter name: :end_time, in: :query, type: :string, required: false,
                description: 'Custom end time (YYYY-MM-DDTHH:MM). Defaults to current time'

      response '200', 'Seasonal audio trends retrieved successfully' do
        example 'application/json', :example, {
          data: {
            period: { start_time: '2025-04-01T00:00:00Z', end_time: '2026-04-01T00:00:00Z' },
            features: %i[valence energy danceability tempo],
            series: [
              {
                month: '2025-06', radio_station_id: 1, radio_station_name: 'Radio 538',
                valence: 0.62, energy: 0.71, danceability: 0.73, tempo: 121.5, sample_size: 450
              },
              {
                month: '2025-12', radio_station_id: 1, radio_station_name: 'Radio 538',
                valence: 0.48, energy: 0.65, danceability: 0.69, tempo: 115.2, sample_size: 420
              }
            ],
            summary: {
              peak_valence_month: '07',
              peak_energy_month: '06',
              peak_danceability_month: '07',
              peak_tempo_month: '06'
            }
          }
        }

        run_test!
      end
    end
  end

  path '/api/v1/radio_stations/{id}/bar_chart_race' do
    get 'Get bar chart race data for a radio station' do
      tags 'Radio Stations'
      produces 'application/json'
      description 'Returns daily top 10 songs with cumulative play counts for bar chart race animation. ' \
                  'Use either period OR start_time/end_time (mutually exclusive). Returns 400 if neither provided.'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Radio station ID'
      parameter name: :period, in: :query, type: :string, required: false,
                description: 'Time period: hour, two_hours, four_hours, eight_hours, twelve_hours, day, week, ' \
                             'month, year, all. Mutually exclusive with start_time/end_time'
      parameter name: :start_time, in: :query, type: :string, required: false,
                description: 'Custom start time (YYYY-MM-DDTHH:MM). Mutually exclusive with period'
      parameter name: :end_time, in: :query, type: :string, required: false,
                description: 'Custom end time (YYYY-MM-DDTHH:MM). Defaults to current time'

      response '200', 'Bar chart race data retrieved successfully' do
        example 'application/json', :example, {
          data: [
            {
              date: '2026-01-10',
              entries: [
                {
                  position: 1,
                  count: 12,
                  song: {
                    id: 1,
                    title: 'Popular Song',
                    spotify_artwork_url: 'https://i.scdn.co/image/abc123',
                    artists: [{ id: 1, name: 'Artist Name' }]
                  }
                }
              ]
            }
          ],
          meta: {
            period: 'week',
            start_time: '2026-01-10T00:00:00Z',
            end_time: '2026-01-17T00:00:00Z'
          }
        }

        let(:radio_station) { create(:radio_station) }
        let(:id) { radio_station.id }
        let(:period) { 'week' }

        run_test!
      end

      response '400', 'Period or start_time parameter is required' do
        example 'application/json', :example, {
          error: 'Period or start_time parameter is required'
        }

        let(:radio_station) { create(:radio_station) }
        let(:id) { radio_station.id }
        let(:period) { nil }

        run_test!
      end

      response '404', 'Radio station not found' do
        example 'application/json', :example, {
          status: 404,
          error: 'Not Found'
        }

        let(:id) { 0 }
        let(:period) { 'week' }

        run_test!
      end
    end
  end

  path '/api/v1/radio_stations/{id}/stream_proxy' do
    get 'Proxy radio station stream' do
      tags 'Radio Stations'
      produces 'audio/mpeg'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Radio station ID'

      let(:resolved_ip) { nil }
      let(:resolv_error) { false }

      before do
        if resolv_error
          allow(Resolv).to receive(:getaddress).and_raise(Resolv::ResolvError)
        elsif resolved_ip
          allow(Resolv).to receive(:getaddress).and_return(resolved_ip)
        end
      end

      response '200', 'Stream proxied successfully' do
        let(:radio_station) { create(:radio_station, direct_stream_url: 'https://example.com/stream') }
        let(:id) { radio_station.id }
        let(:resolved_ip) { '93.184.216.34' }
        let!(:http_stub) { stub_request(:get, 'https://example.com/stream').to_return(status: 200, body: '') }

        run_test!
      end

      response '400', 'No stream URL configured' do
        example 'application/json', :example, {
          error: 'No stream URL configured for this radio station'
        }

        let(:radio_station) { create(:radio_station, direct_stream_url: nil) }
        let(:id) { radio_station.id }

        run_test!
      end

      response '403', 'Forbidden when URL resolves to a private IP' do
        let(:radio_station) { create(:radio_station, direct_stream_url: 'https://example.com/stream') }
        let(:id) { radio_station.id }
        let(:resolved_ip) { '192.168.1.1' }

        run_test!
      end

      response '403', 'Forbidden when URL resolves to a loopback IP' do
        let(:radio_station) { create(:radio_station, direct_stream_url: 'https://example.com/stream') }
        let(:id) { radio_station.id }
        let(:resolved_ip) { '127.0.0.1' }

        run_test!
      end

      response '403', 'Forbidden when URL resolves to a link-local IP' do
        let(:radio_station) { create(:radio_station, direct_stream_url: 'https://example.com/stream') }
        let(:id) { radio_station.id }
        let(:resolved_ip) { '169.254.169.254' }

        run_test!
      end

      response '403', 'Forbidden when hostname cannot be resolved' do
        let(:radio_station) { create(:radio_station, direct_stream_url: 'https://nonexistent.invalid/stream') }
        let(:id) { radio_station.id }
        let(:resolv_error) { true }

        run_test!
      end
    end
  end

  describe 'stream_proxy redirect security' do
    let(:radio_station) { create(:radio_station, direct_stream_url: 'https://stream.example.com/radio.mp3') }

    before do
      allow(Resolv).to receive(:getaddress).with('stream.example.com').and_return('93.184.216.34')
    end

    context 'when redirect points to a private IP' do
      before do
        redirect_response = instance_double(Net::HTTPRedirection, is_a?: false)
        allow(redirect_response).to receive(:is_a?).with(Net::HTTPRedirection).and_return(true)
        allow(redirect_response).to receive(:[]).with('location').and_return('https://internal.example.com/stream')
        allow(Resolv).to receive(:getaddress).with('internal.example.com').and_return('10.0.0.1')
        stub_http_redirect(redirect_response)
      end

      it 'returns 403' do
        get "/api/v1/radio_stations/#{radio_station.id}/stream_proxy"
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when redirect downgrades to HTTP' do
      before do
        redirect_response = instance_double(Net::HTTPRedirection, is_a?: false)
        allow(redirect_response).to receive(:is_a?).with(Net::HTTPRedirection).and_return(true)
        allow(redirect_response).to receive(:[]).with('location').and_return('http://cdn.example.com/stream')
        stub_http_redirect(redirect_response)
      end

      it 'returns 403' do
        get "/api/v1/radio_stations/#{radio_station.id}/stream_proxy"
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when too many redirects occur' do
      before do
        redirect_response = instance_double(Net::HTTPRedirection, is_a?: false)
        allow(redirect_response).to receive(:is_a?).with(Net::HTTPRedirection).and_return(true)
        allow(redirect_response).to receive(:[]).with('location').and_return('https://stream.example.com/radio.mp3')
        stub_http_redirect(redirect_response)
      end

      it 'returns 403' do
        get "/api/v1/radio_stations/#{radio_station.id}/stream_proxy"
        expect(response).to have_http_status(:forbidden)
      end
    end

    def stub_http_redirect(redirect_response)
      allow(Net::HTTP).to receive(:start).with('stream.example.com', 443, use_ssl: true) do |*, &block|
        http = instance_double(Net::HTTP)
        allow(http).to receive(:request).and_yield(redirect_response)
        block.(http)
      end
    end
  end

  describe 'stream_proxy with M3U8 streams' do
    let(:radio_station) { create(:radio_station, direct_stream_url: 'https://stream.example.com/playlist.m3u8') }

    before do
      allow(Resolv).to receive(:getaddress).with('stream.example.com').and_return('93.184.216.34')
    end

    context 'when stream URL is M3U8' do
      let(:fake_stdout) { StringIO.new('fake-mp3-audio-data') }
      let(:fake_stderr) { StringIO.new('') }
      let(:fake_stdin) { StringIO.new }
      let(:wait_thr) { instance_double(Process::Waiter, value: instance_double(Process::Status, success?: true)) }
      let(:expected_cmd) do
        [
          'ffmpeg',
          '-reconnect', '1', '-reconnect_streamed', '1', '-reconnect_delay_max', '30',
          '-re',
          '-i', 'https://stream.example.com/playlist.m3u8',
          '-codec:a', 'libmp3lame', '-f', 'mp3', 'pipe:1'
        ]
      end

      before do
        allow(Open3).to receive(:popen3).with(*expected_cmd).and_yield(fake_stdin, fake_stdout, fake_stderr, wait_thr)
      end

      it 'uses ffmpeg to transcode the stream', :aggregate_failures do
        get "/api/v1/radio_stations/#{radio_station.id}/stream_proxy"

        expect(response).to have_http_status(:ok)
        expect(response.headers['Content-Type']).to eq('audio/mpeg')
        expect(Open3).to have_received(:popen3).with(*expected_cmd)
      end
    end

    context 'when stream URL is M3U8 with private IP' do
      before do
        allow(Resolv).to receive(:getaddress).with('stream.example.com').and_return('192.168.1.1')
      end

      it 'returns 403' do
        get "/api/v1/radio_stations/#{radio_station.id}/stream_proxy"
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
