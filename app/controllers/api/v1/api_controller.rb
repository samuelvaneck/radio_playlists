# frozen_string_literal: true

module Api
  module V1
    class ApiController < ActionController::API
      before_action :authenticate_client!

      rate_limit to: 300, within: 1.minute, by: -> { request.remote_ip }, name: 'general',
                 with: -> { render json: { error: 'Rate limit exceeded' }, status: :too_many_requests }

      rescue_from DateConcern::ConflictingTimeParametersError, with: :render_conflicting_params_error
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::StatementInvalid, ActionController::BadRequest, with: :render_bad_request

      private

      def render_not_found
        render json: { error: 'Not found' }, status: :not_found
      end

      def render_bad_request
        render json: { error: 'Bad request' }, status: :bad_request
      end

      def authenticate_client!
        secret = ENV['FRONTEND_JWT_SECRET']
        return if secret.blank?

        token = request.headers['Authorization']&.delete_prefix('Bearer ')
        return render json: { error: 'Unauthorized' }, status: :unauthorized if token.blank?

        JWT.decode(token, secret, true, algorithm: 'HS256')
      rescue JWT::DecodeError
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end

      def render_conflicting_params_error(exception)
        render json: { error: exception.message }, status: :bad_request
      end

      def pagination_data(items)
        return {} if items.blank?

        { total_entries: items.total_entries || 0, total_pages: items.total_pages || 0, current_page: items.current_page }
      end
    end
  end
end
