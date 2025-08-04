# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Admins::AuthTokenController, type: :controller do
  let(:admin) { create(:admin) }
  let(:session_id) { SecureRandom.hex(16) }
  let(:refresh_token) { create(:refresh_token, admin: admin, session_id: session_id) }

  before do
    sign_in admin
    request.session_options[:id] = session_id
    session[:refresh_token] = { token: refresh_token.token }
  end

  describe '#destroy_refresh_tokens' do
    it 'destroys the refresh token for the current session and admin' do
      expect do
        controller.send(:destroy_refresh_tokens)
      end.to change(RefreshToken, :count).by(-1)
    end

    it 'does nothing if no refresh token is found' do
      session[:refresh_token] = { token: 'nonexistent' }
      expect do
        controller.send(:destroy_refresh_tokens)
      end.not_to change(RefreshToken, :count)
    end
  end

  describe 'POST #reauthorize' do
    context 'when admin is not signed in' do
      before { sign_out admin }

      it 'returns unauthorized' do
        post '/api/v1/admins/auth_token/reauthorize'
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['response']).to eq('Authentication required')
      end
    end

    context 'when refresh token is valid' do
      before do
        allow(controller).to receive(:refresh_token).and_return(refresh_token)
        allow(refresh_token).to receive(:expired?).and_return(false)
      end

      it 'returns success' do
        post :reauthorize
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['status']['message']).to eq('Logged in successfully')
      end
    end

    context 'when refresh token is expired' do
      before do
        allow(controller).to receive(:refresh_token).and_return(refresh_token)
        allow(refresh_token).to receive(:expired?).and_return(true)
      end

      it 'returns unauthorized with error' do
        post :reauthorize
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Invalid refresh token')
      end
    end

    context 'when refresh token is missing' do
      before do
        allow(controller).to receive(:refresh_token).and_return(nil)
      end

      it 'returns unauthorized with error' do
        post :reauthorize
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Invalid refresh token')
      end
    end
  end
end
