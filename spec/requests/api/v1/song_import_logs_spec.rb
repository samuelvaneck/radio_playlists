# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'SongImportLogs API', type: :request do
  path '/api/v1/admins/song_import_logs' do
    get 'List song import logs' do
      tags 'SongImportLogs'
      produces 'application/json'
      security [{ bearer_auth: [] }]
      description 'Returns song import logs for debugging and auditing. Requires admin authentication. ' \
                  'Logs are automatically deleted after 1 day.'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page (default 25)'
      parameter name: :radio_station_id, in: :query, type: :integer, required: false,
                description: 'Filter by radio station ID'
      parameter name: :status, in: :query, type: :string, required: false,
                description: 'Filter by status: pending, success, failed, skipped'
      parameter name: :import_source, in: :query, type: :string, required: false,
                description: 'Filter by import source: recognition, scraping'
      parameter name: :song_id, in: :query, type: :integer, required: false,
                description: 'Filter by song ID'
      parameter name: :llm_action, in: :query, type: :string, required: false,
                description: 'Filter by LLM action: track_name_cleanup, alternative_search_queries, borderline_match_validation'
      parameter name: :created_at_from, in: :query, type: :string, required: false,
                description: 'Filter logs created at or after this timestamp (ISO8601 or YYYY-MM-DD)'
      parameter name: :created_at_to, in: :query, type: :string, required: false,
                description: 'Filter logs created at or before this timestamp (ISO8601 or YYYY-MM-DD)'
      parameter name: :broadcasted_at_from, in: :query, type: :string, required: false,
                description: 'Filter logs broadcasted at or after this timestamp (ISO8601 or YYYY-MM-DD)'
      parameter name: :broadcasted_at_to, in: :query, type: :string, required: false,
                description: 'Filter logs broadcasted at or before this timestamp (ISO8601 or YYYY-MM-DD)'
      parameter name: :linked, in: :query, type: :boolean, required: false,
                description: 'Filter by whether the log is linked to a song (true = has song_id, false = null)'

      let(:admin) { create(:admin) }
      let(:Authorization) { "Bearer #{jwt_token_for(admin)}" }

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

      response '200', 'Filtered by song' do
        let(:song) { create(:song) }
        let!(:log1) { create(:song_import_log, :with_recognition, song:) }
        let!(:log2) { create(:song_import_log, :with_recognition) }
        let(:song_id) { song.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data'].length).to eq(1)
          expect(json['data'].first['attributes']['song']['id']).to eq(song.id)
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

      response '200', 'Filtered by created_at range' do
        let!(:old_log) { create(:song_import_log, :with_recognition, created_at: 3.days.ago) }
        let!(:recent_log) { create(:song_import_log, :with_recognition, created_at: 1.hour.ago) }
        let(:created_at_from) { 2.days.ago.iso8601 }

        run_test! do |response|
          json = JSON.parse(response.body)
          ids = json['data'].map { |d| d['id'].to_i }
          expect(ids).to contain_exactly(recent_log.id)
        end
      end

      response '200', 'Filtered by broadcasted_at range' do
        let!(:old_log) { create(:song_import_log, :with_recognition, broadcasted_at: 3.days.ago) }
        let!(:recent_log) { create(:song_import_log, :with_recognition, broadcasted_at: 1.hour.ago) }
        let(:broadcasted_at_to) { 2.days.ago.iso8601 }

        run_test! do |response|
          json = JSON.parse(response.body)
          ids = json['data'].map { |d| d['id'].to_i }
          expect(ids).to contain_exactly(old_log.id)
        end
      end

      response '200', 'Filtered by llm_action' do
        let!(:log1) { create(:song_import_log, :with_recognition, llm_action: 'track_name_cleanup') }
        let!(:log2) { create(:song_import_log, :with_recognition, llm_action: 'borderline_match_validation') }
        let(:llm_action) { 'track_name_cleanup' }

        run_test! do |response|
          json = JSON.parse(response.body)
          ids = json['data'].map { |d| d['id'].to_i }
          expect(ids).to contain_exactly(log1.id)
        end
      end

      response '200', 'Filtered by linked=false (unlinked logs)' do
        let!(:log1) { create(:song_import_log, :with_recognition, :success) }
        let!(:log2) { create(:song_import_log, :failed) }
        let(:linked) { false }

        run_test! do |response|
          json = JSON.parse(response.body)
          ids = json['data'].map { |d| d['id'].to_i }
          expect(ids).to contain_exactly(log2.id)
        end
      end
    end
  end
end
