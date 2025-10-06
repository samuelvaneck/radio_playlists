# frozen_string_literal: true

module Api
  module V1
    module Admins
      class ReauthorizeController < ApiController
        skip_before_action :authenticate_admin!

        def create
          # Try to get refresh token from cookie first (web clients), then fallback to request body (mobile/API clients)
          token_param = cookies.encrypted[:refresh_token] || params[:refresh_token]

          if token_param.blank?
            render json: { error: 'Refresh token is required' }, status: :bad_request
            return
          end

          refresh_token = RefreshToken.find_by(token: token_param)

          if refresh_token.nil?
            render json: { error: 'Invalid refresh token' }, status: :unauthorized
            return
          end

          if refresh_token.expired?
            refresh_token.destroy
            cookies.delete(:refresh_token) # Clear expired cookie
            render json: { error: 'Refresh token expired' }, status: :unauthorized
            return
          end

          admin = refresh_token.admin
          jwt_token = Warden::JWTAuth::UserEncoder.new.call(admin, :admin, nil).first

          # Update cookie if present (web clients)
          if cookies.encrypted[:refresh_token].present?
            cookies.encrypted[:refresh_token] = {
              value: refresh_token.token,
              httponly: true,
              secure: Rails.env.production?,
              same_site: :lax,
              expires: refresh_token.expires_at
            }
          end

          render json: {
            token: jwt_token,
            refresh_token: refresh_token.token,
            refresh_token_expires_at: refresh_token.expires_at
          }, status: :ok
        rescue StandardError => e
          Rails.logger.error("Reauthorize Error: #{e.message}")
          render json: { error: 'Failed to generate new token' }, status: :internal_server_error
        end
      end
    end
  end
end
