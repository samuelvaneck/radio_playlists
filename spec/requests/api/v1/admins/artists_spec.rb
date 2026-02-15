# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Admin Artists API', type: :request do
  let(:admin) { create(:admin) }
  let(:Authorization) { "Bearer #{jwt_token_for(admin)}" }

  path '/api/v1/admins/artists' do
    get 'List artists for admin' do
      tags 'Admin Artists'
      security [{ bearer_auth: [] }]
      produces 'application/json'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'
      parameter name: :search_term, in: :query, type: :string, required: false, description: 'Search by name'

      response '200', 'Artists retrieved successfully' do
        let!(:artist) { create(:artist) }

        run_test!
      end

      response '401', 'Not authenticated' do
        let(:Authorization) { 'Bearer invalid_token' }

        run_test!
      end
    end
  end

  path '/api/v1/admins/artists/{id}' do
    patch 'Update an artist' do
      tags 'Admin Artists'
      security [{ bearer_auth: [] }]
      consumes 'application/json'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Artist ID'
      parameter name: :artist, in: :body, schema: {
        type: :object,
        properties: {
          artist: {
            type: :object,
            properties: {
              website_url: { type: :string },
              instagram_url: { type: :string }
            }
          }
        }
      }

      response '200', 'Artist updated successfully' do
        let(:existing_artist) { create(:artist) }
        let(:id) { existing_artist.id }
        let(:artist) { { artist: { website_url: 'https://example.com', instagram_url: 'https://instagram.com/artist' } } }

        run_test!
      end

      response '401', 'Not authenticated' do
        let(:Authorization) { 'Bearer invalid_token' }
        let(:existing_artist) { create(:artist) }
        let(:id) { existing_artist.id }
        let(:artist) { { artist: { website_url: 'https://example.com' } } }

        run_test!
      end

      response '404', 'Artist not found' do
        let(:id) { 0 }
        let(:artist) { { artist: { website_url: 'https://example.com' } } }

        run_test!
      end
    end
  end
end
