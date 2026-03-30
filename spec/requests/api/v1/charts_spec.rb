# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Charts API', type: :request do
  path '/api/v1/charts' do
    get 'List chart positions' do
      tags 'Charts'
      produces 'application/json'
      description 'Returns chart positions with optional type, date, and pagination. ' \
                  'Includes previous_position from the prior chart for movement indicators.'
      parameter name: :type, in: :query, type: :string, required: false,
                description: 'Chart type: songs (default) or artists'
      parameter name: :date, in: :query, type: :string, format: :date, required: false,
                description: 'Chart date (YYYY-MM-DD). Defaults to latest available'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'

      response '200', 'Chart positions retrieved successfully' do
        example 'application/json', :example, {
          data: [
            {
              id: '1',
              type: 'chart_position',
              attributes: {
                position: 1,
                counts: 42,
                previous_position: 3,
                song: {
                  id: '5',
                  type: 'song',
                  attributes: {
                    id: 5,
                    title: 'Bohemian Rhapsody',
                    spotify_artwork_url: 'https://i.scdn.co/image/abc123',
                    artists: [{ id: 1, name: 'Queen' }]
                  }
                },
                artist: nil
              }
            }
          ],
          chart_date: '2026-03-01',
          chart_type: 'songs',
          total_entries: 150,
          total_pages: 7,
          current_page: 1
        }

        let!(:chart) { create(:chart, chart_type: 'songs', date: 1.day.ago.to_date) }
        let!(:song) { create(:song, title: 'Test Song') }
        let!(:chart_position) { create(:chart_position, chart: chart, positianable: song, position: 1, counts: 42) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['data'].first['attributes']['position']).to eq(1)
        end
      end

      context 'with artist chart type' do
        response '200', 'Artist chart positions retrieved' do
          let(:type) { 'artists' }
          let!(:chart) { create(:chart, chart_type: 'artists', date: 1.day.ago.to_date) }
          let!(:artist) { create(:artist, name: 'Test Artist') }
          let!(:chart_position) { create(:chart_position, chart: chart, positianable: artist, position: 1, counts: 30) }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['chart_type']).to eq('artists')
          end
        end
      end

      context 'with specific date' do
        response '200', 'Chart for specific date' do
          let(:date) { 3.days.ago.to_date.to_s }
          let!(:chart) { create(:chart, chart_type: 'songs', date: 3.days.ago.to_date) }
          let!(:chart_position) { create(:chart_position, chart: chart, position: 1, counts: 20) }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['chart_date']).to eq(3.days.ago.to_date.to_s)
          end
        end
      end

      context 'with previous positions' do
        response '200', 'Chart with previous position data' do
          let!(:song) { create(:song) }
          let!(:previous_chart) { create(:chart, chart_type: 'songs', date: 2.days.ago.to_date) }
          let!(:previous_position) { create(:chart_position, chart: previous_chart, positianable: song, position: 3, counts: 30) }
          let!(:chart) { create(:chart, chart_type: 'songs', date: 1.day.ago.to_date) }
          let!(:chart_position) { create(:chart_position, chart: chart, positianable: song, position: 1, counts: 42) }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['data'].first['attributes']['previous_position']).to eq(3)
          end
        end
      end

      context 'without previous chart' do
        response '200', 'Chart with nil previous positions' do
          let!(:chart) { create(:chart, chart_type: 'songs', date: 1.day.ago.to_date) }
          let!(:chart_position) { create(:chart_position, chart: chart, position: 1, counts: 42) }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['data'].first['attributes']['previous_position']).to be_nil
          end
        end
      end

      context 'with pagination' do
        response '200', 'Paginated chart positions' do
          let(:page) { 2 }
          let!(:chart) { create(:chart, chart_type: 'songs', date: 1.day.ago.to_date) }
          let!(:chart_positions) { create_list(:chart_position, 25, chart: chart) }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['current_page']).to eq(2)
            expect(data['total_pages']).to eq(2)
          end
        end
      end

      response '404', 'Chart not found for given date' do
        example 'application/json', :example, {
          status: 404,
          error: 'Not Found'
        }

        let(:date) { '2020-01-01' }

        run_test!
      end
    end
  end

  path '/api/v1/charts/search' do
    get 'Search chart positions by song title or artist name' do
      tags 'Charts'
      produces 'application/json'
      description 'Search within chart positions by song title or artist name. ' \
                  'Returns matching chart positions with previous_position for movement indicators.'
      parameter name: :search_term, in: :query, type: :string, required: true,
                description: 'Search term to match against song title or artist name'
      parameter name: :date, in: :query, type: :string, format: :date, required: false,
                description: 'Chart date (YYYY-MM-DD). Defaults to latest available'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'

      response '200', 'Matching chart positions retrieved successfully' do
        example 'application/json', :example, {
          data: [
            {
              id: '1',
              type: 'chart_position',
              attributes: {
                position: 3,
                counts: 35,
                previous_position: 5,
                song: {
                  id: '5',
                  type: 'song',
                  attributes: {
                    id: 5,
                    title: 'Hello',
                    spotify_artwork_url: 'https://i.scdn.co/image/abc123',
                    artists: [{ id: 1, name: 'Adele' }]
                  }
                },
                artist: nil
              }
            }
          ],
          chart_date: '2026-03-01',
          chart_type: 'songs',
          total_entries: 1,
          total_pages: 1,
          current_page: 1
        }

        let(:search_term) { 'Hello' }
        let!(:chart) { create(:chart, chart_type: 'songs', date: 1.day.ago.to_date) }
        let!(:song) { create(:song, title: 'Hello', search_text: 'Adele Hello') }
        let!(:other_song) { create(:song, title: 'Blinding Lights', search_text: 'The Weeknd Blinding Lights') }
        let!(:chart_position) { create(:chart_position, chart: chart, positianable: song, position: 1, counts: 42) }
        let!(:other_position) { create(:chart_position, chart: chart, positianable: other_song, position: 2, counts: 30) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['data'].length).to eq(1)
          expect(data['data'].first['attributes']['position']).to eq(1)
        end
      end

      context 'with specific date' do
        response '200', 'Search within chart for specific date' do
          let(:search_term) { 'Hello' }
          let(:date) { 3.days.ago.to_date.to_s }
          let!(:chart) { create(:chart, chart_type: 'songs', date: 3.days.ago.to_date) }
          let!(:song) { create(:song, title: 'Hello', search_text: 'Adele Hello') }
          let!(:chart_position) { create(:chart_position, chart: chart, positianable: song, position: 5, counts: 20) }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['chart_date']).to eq(3.days.ago.to_date.to_s)
          end
        end
      end

      context 'with no matches' do
        response '200', 'Empty results when no songs match' do
          let(:search_term) { 'Nonexistent' }
          let!(:chart) { create(:chart, chart_type: 'songs', date: 1.day.ago.to_date) }
          let!(:song) { create(:song, title: 'Hello', search_text: 'Adele Hello') }
          let!(:chart_position) { create(:chart_position, chart: chart, positianable: song, position: 1, counts: 42) }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['data']).to be_empty
          end
        end
      end
    end
  end

  path '/api/v1/charts/autocomplete' do
    get 'Autocomplete songs' do
      tags 'Charts'
      produces 'application/json'
      description 'Search all songs for autocomplete, sorted by popularity.'
      parameter name: :q, in: :query, type: :string, required: true,
                description: 'Search query string'
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: 'Maximum number of results (default: 10, max: 20)'

      response '200', 'Autocomplete results' do
        example 'application/json', :autocomplete_result, {
          data: [
            {
              id: '1',
              type: 'song',
              attributes: {
                id: 1,
                title: 'Hello',
                spotify_artwork_url: 'https://example.com/artwork.jpg',
                artists: [{ id: 1, name: 'Adele' }]
              }
            }
          ]
        }

        let(:q) { 'Hello' }
        let!(:artist) { create(:artist, name: 'Adele') }
        let!(:song) { create(:song, title: 'Hello', artists: [artist], search_text: 'Adele Hello') }
        let!(:chart) { create(:chart, chart_type: 'songs', date: Date.current) }
        let!(:chart_position) { create(:chart_position, chart: chart, positianable: song, position: 1, counts: 10) }

        run_test! do |response|
          data = JSON.parse(response.body)
          song_attrs = data['data'].first['attributes']
          expect(song_attrs['title']).to eq('Hello')
        end
      end

      context 'when query matches nothing' do
        response '200', 'Empty results' do
          let(:q) { 'Nonexistent' }
          let!(:chart) { create(:chart, chart_type: 'songs', date: Date.current) }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['data']).to be_empty
          end
        end
      end
    end
  end
end
