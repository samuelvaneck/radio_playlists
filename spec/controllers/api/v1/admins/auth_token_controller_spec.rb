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
end
