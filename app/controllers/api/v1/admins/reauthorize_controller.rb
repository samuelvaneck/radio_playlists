# frozen_string_literal: true

module Api
  module V1
    module Admins
      class ReauthorizeController < ApplicationController
        skip_before_action :authenticate_admin!

        def create
          refresh_token = RefreshToken.find_by(session_id:, token: session[:refresh_token][:token])

          if refresh_token&.expired?
            refresh_token.destroy
            render json: { error: 'Refresh token expired' }, status: :unauthorized
            return
          end

          if refresh_token
            user = refresh_token.user
            token = Warden::JWTAuth::UserEncoder.new.(user, :admins, nil).first
            render json: { token: }, status: :ok
          else
            render json: { error: 'Invalid refresh token' }, status: :unauthorized
          end
        rescue JWT::DecodeError => e
          Rails.logger.error("JWT Decode Error: #{e.message}")
          render json: { error: 'Invalid token' }, status: :unauthorized
        end
      end
    end
  end
end
