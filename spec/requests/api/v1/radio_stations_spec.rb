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
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Radio station ID'

      response '200', 'Radio station retrieved successfully' do
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
              radio_station: {
                id: 1,
                name: 'Radio 538',
                slug: 'radio-538'
              },
              last_song: {
                id: 1,
                title: 'Bohemian Rhapsody',
                artists: [{ id: 1, name: 'Queen' }],
                broadcasted_at: '2024-12-01T14:30:00Z'
              }
            },
            {
              radio_station: {
                id: 2,
                name: 'Qmusic',
                slug: 'qmusic'
              },
              last_song: {
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

  path '/api/v1/radio_stations/{id}/timeline' do
    get 'Get radio station timeline with daily plays' do
      tags 'Radio Stations'
      produces 'application/json'
      description 'Returns most played songs for a radio station with day-by-day play distribution. ' \
                  'Use either period OR start_time/end_time (mutually exclusive). Returns 400 if neither provided.'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Radio station ID'
      parameter name: :period, in: :query, type: :string, required: false,
                description: 'Time period: hour, two_hours, four_hours, eight_hours, twelve_hours, day, week, ' \
                             'month, year, all. Mutually exclusive with start_time/end_time'
      parameter name: :start_time, in: :query, type: :string, required: false,
                description: 'Custom start time (YYYY-MM-DDTHH:MM). Mutually exclusive with period'
      parameter name: :end_time, in: :query, type: :string, required: false,
                description: 'Custom end time (YYYY-MM-DDTHH:MM). Defaults to current time'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false,
                description: 'Items per page (default: 24)'

      response '200', 'Timeline retrieved successfully' do
        example 'application/json', :example, {
          data: [
            {
              id: '1',
              type: 'song',
              attributes: {
                title: 'Popular Song',
                counter: 50,
                position: 1,
                daily_plays: {
                  '2026-01-10': 8,
                  '2026-01-11': 12,
                  '2026-01-12': 10
                },
                artists: [{ id: '1', name: 'Artist Name' }],
                spotify_artwork_url: 'https://i.scdn.co/image/abc123'
              }
            }
          ],
          meta: {
            period: 'week',
            start_time: '2026-01-10T00:00:00Z',
            end_time: '2026-01-17T00:00:00Z'
          },
          total_entries: 120,
          total_pages: 5,
          current_page: 1
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
end
