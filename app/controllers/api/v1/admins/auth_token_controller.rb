# frozen_string_literal: true

module Api
  module V1
    module Admins
      class AuthTokenController < Devise::SessionsController
        include Devise::Controllers::Helpers

        before_action :allow_params_authentication!
        # before_action :set_admin
        # before_action :configure_sign_in_params, only: [:create]

        # GET /resource/sign_in
        def new
          super
          respond_with(@admin)
        end

        # POST /resource/sign_in
        def create
        return render json: { response: "Authentication required" }, status: 401 unless current_admin

        respond_with(current_admin)

          # token  = Warden::JWTAuth::UserEncoder.new.call(current_admin, :admin, "")


          # self.resource = warden.authenticate!(auth_options)
          # set_flash_message!(:notice, :signed_in)
          # sign_in(resource_name, resource)
          # yield resource if block_given?

          # token =

          # render json: resource.session_json
        end

        # DELETE /resource/sign_out
        # def destroy
        #   super
        # end

        # protected

        # If you have extra params to permit, append them to the sanitizer.
        def configure_sign_in_params
          devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
        end

        private

        def set_admin
          @admin = Admin.find_by(email: params[:admin][:email])
        end

        def respond_with(admin, _opts = {})
          data = AdminSerializer.new(admin).serializable_hash[:data][:attributes]
          data[:token] = current_token

          render json: {
            status: { code: 200, message: 'Logged in sucessfully.' },
            data: data
          }, status: :ok
        end

        def respond_to_on_destroy
          if current_admin
            render json: {
              status: 200,
              message: "logged out successfully"
            }, status: :ok
          else
            render json: {
              status: 401,
              message: "Couldn't find an active session."
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
