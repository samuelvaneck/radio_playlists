# frozen_string_literal: true

module FrontendAuthHelper
  FRONTEND_JWT_SECRET = 'test-frontend-jwt-secret'

  def frontend_auth_headers
    token = ClientTokenGenerator.new('test-client').()
    { 'Authorization' => "Bearer #{token}" }
  end

  def enable_frontend_auth!
    ENV['FRONTEND_JWT_SECRET'] = FRONTEND_JWT_SECRET
  end

  def disable_frontend_auth!
    ENV.delete('FRONTEND_JWT_SECRET')
  end
end

RSpec.configure do |config|
  config.include FrontendAuthHelper, type: :request
end
