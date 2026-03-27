# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API Authentication', type: :request do
  before { enable_frontend_auth! }

  after { disable_frontend_auth! }

  describe 'JWT authentication' do
    context 'without Authorization header' do
      it 'returns unauthorized' do
        get '/api/v1/radio_stations'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized' do
        get '/api/v1/radio_stations', headers: { 'Authorization' => 'Bearer invalid-token' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with expired token' do
      it 'returns unauthorized' do
        token = JWT.encode(
          { client_id: 'test', exp: 1.hour.ago.to_i, iat: 2.hours.ago.to_i },
          FrontendAuthHelper::FRONTEND_JWT_SECRET,
          'HS256'
        )

        get '/api/v1/radio_stations', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with valid token' do
      it 'allows the request' do
        get '/api/v1/radio_stations', headers: frontend_auth_headers

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when FRONTEND_JWT_SECRET is not set' do
      before { disable_frontend_auth! }

      it 'allows all requests without authentication' do
        get '/api/v1/radio_stations'

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'widget endpoints skip authentication' do
    let!(:song) { create(:song) }
    let!(:artist) { create(:artist) }
    let!(:radio_station) { create(:radio_station) }

    it 'allows song widget without auth' do
      get "/api/v1/songs/#{song.id}/widget"

      expect(response).to have_http_status(:ok)
    end

    it 'allows artist widget without auth' do
      get "/api/v1/artists/#{artist.id}/widget"

      expect(response).to have_http_status(:ok)
    end

    it 'allows radio station widget without auth' do
      get "/api/v1/radio_stations/#{radio_station.id}/widget"

      expect(response).to have_http_status(:ok)
    end
  end
end
