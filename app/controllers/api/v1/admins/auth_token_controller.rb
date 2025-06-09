# frozen_string_literal: true

module Api
  module V1
    module Admins
      class AuthTokenController < Devise::SessionsController
        respond_to :json
        before_action :destroy_refresh_token, only: [:destroy]

        # POST /resource/sign_in
        def create
          return render json: { response: 'Authentication required' }, status: :unauthorized unless current_admin

          respond_with(current_admin)
        end

        private

        def respond_with(admin, _opts = {})
          data = AdminSerializer.new(admin).serializable_hash[:data][:attributes]
          data[:token] = current_token
          create_refresh_token

          render json: {
            status: { code: 200, message: 'Logged in successfully' },
            data:
          }, status: :ok
        end

        def current_token
          request.env['warden-jwt_auth.token']
        end

        def create_refresh_token
          return if session[:refresh_token].present?

          refresh_token = current_admin.refresh_tokens.create!
          session[:refresh_token] = refresh_token.token
        end

        def respond_to_on_destroy
          render json: { message: 'Logged out successfully' }, status: :ok
        end

        def destroy_refresh_token
          return if session[:refresh_token].blank?

          refresh_token = current_admin.refresh_tokens.find_by(token: session[:refresh_token])
          return unless refresh_token

          refresh_token.destroy
          cookies.delete(:refresh_token)
        end
      end
    end
  end
end
