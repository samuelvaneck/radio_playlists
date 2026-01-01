# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'SongImportLogs API', type: :request do
  path '/api/v1/song_import_logs' do
    get 'List song import logs' do
      tags 'SongImportLogs'
      produces 'application/json'
      description 'Returns song import logs for debugging and auditing. Logs are automatically deleted after 1 day.'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page (default 25)'
      parameter name: :radio_station_id, in: :query, type: :integer, required: false,
                description: 'Filter by radio station ID'
      parameter name: :status, in: :query, type: :string, required: false,
                description: 'Filter by status: pending, success, failed, skipped'
      parameter name: :import_source, in: :query, type: :string, required: false,
                description: 'Filter by import source: recognition, scraping'

      response '200', 'Song import logs retrieved successfully' do
        let!(:song_import_log) { create(:song_import_log, :with_recognition) }

        run_test!
      end

      response '200', 'Filtered by status' do
        let!(:failed_log) { create(:song_import_log, :failed) }
        let!(:success_log) { create(:song_import_log, :with_recognition, status: :success) }
        let(:status) { 'failed' }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data'].length).to eq(1)
          expect(json['data'].first['attributes']['status']).to eq('failed')
        end
      end

      response '200', 'Filtered by radio station' do
        let(:radio_station) { create(:radio_station) }
        let!(:log1) { create(:song_import_log, :with_recognition, radio_station:) }
        let!(:log2) { create(:song_import_log, :with_recognition) }
        let(:radio_station_id) { radio_station.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data'].length).to eq(1)
          expect(json['data'].first['attributes']['radio_station']['id']).to eq(radio_station.id)
        end
      end
    end
  end
end
