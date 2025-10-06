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
          # Create refresh token for this session
          refresh_token = RefreshToken.create!(admin: admin, session_id: session_id)

          # Set refresh token as HttpOnly cookie for web clients
          cookies.encrypted[:refresh_token] = {
            value: refresh_token.token,
            httponly: true,
            secure: Rails.env.production?, # Only send over HTTPS in production
            same_site: :lax,
            expires: refresh_token.expires_at
          }

          data = AdminSerializer.new(admin).serializable_hash[:data][:attributes]
          data[:token] = current_token
          # Also include in response body for mobile/non-browser clients
          data[:refresh_token] = refresh_token.token
          data[:refresh_token_expires_at] = refresh_token.expires_at

          render json: {
            status: { code: 200, message: 'Logged in successfully' },
            data:
          }, status: :ok
        end

        def current_token
          request.env['warden-jwt_auth.token']
        end

        def respond_to_on_destroy
          cookies.delete(:refresh_token) # Clear refresh token cookie
          render json: { message: 'Logged out successfully' }, status: :ok
        end

        def destroy_refresh_tokens
          return if current_admin.blank?

          # Destroy all refresh tokens for this admin on logout
          current_admin.refresh_tokens.destroy_all
        rescue StandardError => e
          Rails.logger.error("Error destroying refresh tokens: #{e.message}")
        end

        def session_id
          request.session_options[:id].to_s
        end
      end
    end
  end
end
