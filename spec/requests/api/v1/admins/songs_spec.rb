# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Admin Songs API', type: :request do
  let(:admin) { create(:admin) }
  let(:Authorization) { "Bearer #{jwt_token_for(admin)}" }

  path '/api/v1/admins/songs' do
    get 'List songs for admin' do
      tags 'Admin Songs'
      security [bearer_auth: []]
      produces 'application/json'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'
      parameter name: :search_term, in: :query, type: :string, required: false, description: 'Search by title'

      response '200', 'Songs retrieved successfully' do
        let!(:song) { create(:song) }

        run_test!
      end

      response '401', 'Not authenticated' do
        let(:Authorization) { 'Bearer invalid_token' }

        run_test!
      end
    end
  end

  path '/api/v1/admins/songs/{id}' do
    patch 'Update a song' do
      tags 'Admin Songs'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Song ID'
      parameter name: :song, in: :body, schema: {
        type: :object,
        properties: {
          song: {
            type: :object,
            properties: {
              id_on_youtube: { type: :string }
            }
          }
        }
      }

      response '200', 'Song updated successfully' do
        let(:existing_song) { create(:song) }
        let(:id) { existing_song.id }
        let(:song) { { song: { id_on_youtube: 'dQw4w9WgXcQ' } } }

        run_test!
      end

      response '401', 'Not authenticated' do
        let(:Authorization) { 'Bearer invalid_token' }
        let(:existing_song) { create(:song) }
        let(:id) { existing_song.id }
        let(:song) { { song: { id_on_youtube: 'dQw4w9WgXcQ' } } }

        run_test!
      end

      response '404', 'Song not found' do
        let(:id) { 0 }
        let(:song) { { song: { id_on_youtube: 'dQw4w9WgXcQ' } } }

        run_test!
      end
    end
  end
end
