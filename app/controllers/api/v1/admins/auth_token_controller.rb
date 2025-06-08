# frozen_string_literal: true

module Api
  module V1
    module Admins
      class AuthTokenController < Devise::SessionsController
        respond_to :json
        skip_before_action :verify_signed_out_user, only: [:destroy]

        # POST /resource/sign_in
        def create
          return render json: { response: 'Authentication required' }, status: :unauthorized unless current_admin

          respond_with(current_admin)
        end

        # DELETE /resource/sign_out
        def destroy
          destroy_refresh_token
          super
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
          return if cookies.encrypted[:refresh_token].present?

          refresh_token = current_admin.refresh_tokens.create!
          cookies.encrypted[:refresh_token] = {
            value: refresh_token.token,
            httponly: true,
            secure: Rails.env.production?,
            expires: 2.weeks.from_now
          }
        end

        def respond_to_on_destroy
          render json: { message: 'Logged out successfully' }, status: :ok
        end

        def destroy_refresh_token
          return if cookies.encrypted[:refresh_token].blank?

          refresh_token = current_admin.refresh_tokens.find_by(token: cookies.encrypted[:refresh_token])
          return unless refresh_token

          refresh_token.destroy
          cookies.delete(:refresh_token)
        end
      end
    end
  end
end
