# frozen_string_literal: true

module Api
  module V1
    module Admins
      class AuthTokenController < Devise::SessionsController
        # POST /resource/sign_in
        def create
          return render json: { response: 'Authentication required' }, status: :unauthorized unless current_admin

          respond_with(current_admin)
        end

        private

        def respond_with(admin, _opts = {})
          data = AdminSerializer.new(admin).serializable_hash[:data][:attributes]
          data[:token] = current_token

          render json: {
            status: { code: 200, message: 'Logged in successfully' },
            data: data
          }, status: :ok
        end

        def respond_to_on_destroy
          if current_admin
            render json: {
              status: 200,
              message: 'Logged out successfully'
            }, status: :ok
          else
            render json: {
              status: 401,
              message: "Couldn't find an active session"
            }, status: :unauthorized
          end
        end

        def current_token
          request.env['warden-jwt_auth.token']
        end
      end
    end
  end
end
