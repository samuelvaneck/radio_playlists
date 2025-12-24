# frozen_string_literal: true

module JwtAuthHelper
  def jwt_token_for(admin)
    Warden::JWTAuth::UserEncoder.new.call(admin, :admin, nil).first
  end
end

RSpec.configure do |config|
  config.include JwtAuthHelper, type: :request
end
