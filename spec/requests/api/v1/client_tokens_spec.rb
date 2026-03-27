# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Client Tokens API', type: :request do
  let(:client_id) { 'test-client-id' }
  let(:client_secret) { 'test-client-secret' }

  before do
    ENV['FRONTEND_CLIENT_ID'] = client_id
    ENV['FRONTEND_CLIENT_SECRET'] = client_secret
    ENV['FRONTEND_JWT_SECRET'] = FrontendAuthHelper::FRONTEND_JWT_SECRET
  end

  after do
    ENV.delete('FRONTEND_CLIENT_ID')
    ENV.delete('FRONTEND_CLIENT_SECRET')
    ENV.delete('FRONTEND_JWT_SECRET')
  end

  describe 'POST /api/v1/client_tokens' do
    context 'with valid credentials' do
      it 'returns a JWT token', :aggregate_failures do
        post '/api/v1/client_tokens', params: { client_id: client_id, client_secret: client_secret }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['token']).to be_present
        expect(json['expires_in']).to eq(600)
      end

      it 'returns a token that can authenticate API requests', :aggregate_failures do
        post '/api/v1/client_tokens', params: { client_id: client_id, client_secret: client_secret }

        token = JSON.parse(response.body)['token']
        get '/api/v1/radio_stations', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized', :aggregate_failures do
        post '/api/v1/client_tokens', params: { client_id: 'wrong', client_secret: 'wrong' }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Invalid client credentials')
      end
    end

    context 'with missing credentials' do
      it 'returns unauthorized' do
        post '/api/v1/client_tokens', params: {}

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
