# frozen_string_literal: true

module Api
  module V1
    module Admins
      class RefreshTokensController < ApplicationController
        def create
          refresh_token = RefreshToken.find_by(token: params[:refresh_token])

          if refresh_token&.expired?
            refresh_token.destroy
            render json: { error: 'Refresh token expired' }, status: :unauthorized
            return
          end

          if refresh_token
            user = refresh_token.user
            jwt = Warden::JWTAuth::UserEncoder.new.(user, :user, nil).first
            render json: { access_token: jwt }, status: :ok
          else
            render json: { error: 'Invalid refresh token' }, status: :unauthorized
          end
        end
      end
    end
  end
end
