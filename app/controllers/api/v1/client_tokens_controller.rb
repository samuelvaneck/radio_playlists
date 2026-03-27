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

        token = ClientTokenGenerator.new(client_id).()
        render json: { token: token, expires_in: ClientTokenGenerator::TOKEN_EXPIRY.to_i }
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
    end
  end
end
