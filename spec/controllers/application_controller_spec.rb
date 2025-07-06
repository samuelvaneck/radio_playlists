# frozen_string_literal: true

require 'rails_helper'

describe ApplicationController, type: :controller do
  controller do
    # Expose the private method for testing
    public :maybe_set_refresh_token?
  end

  let(:admin) { create(:admin) }
  let(:session_id) { SecureRandom.hex(16) }

  before do
    sign_in admin
    request.session_options[:id] = session_id
    request.session_options[:skip] = false
  end

  context 'when none exists' do
    it 'creates a new refresh token' do
      expect do
        controller.maybe_set_refresh_token?
      end.to change(RefreshToken, :count).by(1)
    end

    it 'sets the refresh token in the session' do
      controller.maybe_set_refresh_token?
      expect(session[:refresh_token]).to be_present
    end
  end

  context 'when the session is skipped' do
    it 'does not create a new token' do
      request.session_options[:skip] = true
      expect do
        controller.maybe_set_refresh_token?
      end.not_to change(RefreshToken, :count)
    end
  end

  context 'when the refresh token is expired' do
    let(:token) { RefreshToken.create!(admin:, session_id:) }

    before do
      session[:refresh_token] = { token: token.token, expires_at: (2.weeks.from_now + 1.minute) }
    end

    it 'removes old refresh token' do
      expect do
        controller.maybe_set_refresh_token?
      end.not_to change(RefreshToken, :count) # one destroyed, one created
    end
  end

  context 'when the refresh token is present and expired' do
    let(:token) { RefreshToken.create!(admin:, session_id:) }

    before do
      session[:refresh_token] = { refresh_token: token.token, expires_at: 1.hour.ago }
    end

    it 'does nothing' do
      expect do
        controller.maybe_set_refresh_token?
      end.not_to change(RefreshToken, :count)
    end
  end
end
