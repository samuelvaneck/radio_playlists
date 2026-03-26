# frozen_string_literal: true

module Api
  module V1
    class ClientTokensController < ActionController::API
      rate_limit to: 10, within: 1.minute, by: -> { request.remote_ip },
                 with: -> { render json: { error: 'Rate limit exceeded' }, status: :too_many_requests }

      def create
        client_id = params[:client_id]
        client_secret = params[:client_secret]

        return render json: { error: 'Invalid client credentials' }, status: :unauthorized unless valid_client_credentials?(client_id, client_secret)

        token = generate_token(client_id)
        render json: { token: token, expires_in: 1.hour.to_i }
      end

      private

      def valid_client_credentials?(client_id, client_secret)
        expected_id = ENV['FRONTEND_CLIENT_ID']
        expected_secret = ENV['FRONTEND_CLIENT_SECRET']

        return false if expected_id.blank? || expected_secret.blank?
        return false if client_id.blank? || client_secret.blank?

        ActiveSupport::SecurityUtils.secure_compare(client_id, expected_id) &&
          ActiveSupport::SecurityUtils.secure_compare(client_secret, expected_secret)
      end

      def generate_token(client_id)
        payload = {
          client_id: client_id,
          exp: 1.hour.from_now.to_i,
          iat: Time.current.to_i
        }
        JWT.encode(payload, ENV['FRONTEND_JWT_SECRET'], 'HS256')
      end
    end
  end
end
