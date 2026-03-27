# frozen_string_literal: true

class ClientTokenGenerator
  TOKEN_EXPIRY = 10.minutes

  def initialize(client_id)
    @client_id = client_id
  end

  def call
    payload = {
      client_id: @client_id,
      exp: TOKEN_EXPIRY.from_now.to_i,
      iat: Time.current.to_i
    }
    JWT.encode(payload, ENV['FRONTEND_JWT_SECRET'], 'HS256')
  end
end
