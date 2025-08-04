# frozen_string_literal: true

module Api
  module V1
    module Admins
      class AuthTokenController < Devise::SessionsController
        respond_to :json

        # POST /resource/sign_in
        def create
          return render json: { response: 'Authentication required' }, status: :unauthorized unless current_admin

          respond_with(current_admin)
        end

        protected

        def verify_signed_out_user
          super
          destroy_refresh_tokens
        end

        private

        def respond_with(admin, _opts = {})
          data = AdminSerializer.new(admin).serializable_hash[:data][:attributes]
          data[:token] = current_token

          render json: {
            status: { code: 200, message: 'Logged in successfully' },
            data:
          }, status: :ok
        end

        def current_token
          request.env['warden-jwt_auth.token']
        end

        def respond_to_on_destroy
          render json: { message: 'Logged out successfully' }, status: :ok
        end

        def destroy_refresh_tokens
          session_token = session.delete(:refresh_token)
          return if session_token.blank?

          refresh_token = RefreshToken.find_by(token: session_token[:token], session_id:, admin: current_admin)
          refresh_token&.destroy
        rescue JWT::DecodeError => e
          Rails.logger.error("JWT Decode Error: #{e.message}")
        end
      end
    end
  end
end
