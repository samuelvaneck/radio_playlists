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

  path '/api/v1/admins/artists/{id}/refresh_timeline' do
    post 'Force a refresh of an artist timeline' do
      tags 'Admin Artists'
      security [{ bearer_auth: [] }]
      produces 'application/json'
      description 'Enqueues an ArtistTimelineEnrichmentJob to rebuild the cached MusicBrainz + Wikidata timeline ' \
                  'for an artist. Returns 422 if the artist has no MusicBrainz ID.'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Artist ID'

      response '202', 'Timeline refresh enqueued' do
        let(:existing_artist) { create(:artist, id_on_musicbrainz: '056e4f3e-d505-4dad-8ec1-d04f521cbb56') }
        let(:id) { existing_artist.id }

        before { allow(ArtistTimelineEnrichmentJob).to receive(:perform_async) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to include('status' => 'enqueued', 'artist_id' => existing_artist.id), :aggregate_failures
          expect(ArtistTimelineEnrichmentJob).to have_received(:perform_async).with(existing_artist.id)
        end
      end

      response '422', 'Artist has no MusicBrainz ID' do
        let(:existing_artist) { create(:artist, id_on_musicbrainz: nil) }
        let(:id) { existing_artist.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['errors']).to include(a_string_matching(/MusicBrainz/))
        end
      end

      response '401', 'Not authenticated' do
        let(:Authorization) { 'Bearer invalid_token' }
        let(:existing_artist) { create(:artist, id_on_musicbrainz: '056e4f3e-d505-4dad-8ec1-d04f521cbb56') }
        let(:id) { existing_artist.id }

        run_test!
      end

      response '404', 'Artist not found' do
        let(:id) { 0 }

        run_test!
      end
    end
  end
end
