# frozen_string_literal: true

module Api
  module V1
    class ApiController < ActionController::API
      rescue_from DateConcern::ConflictingTimeParametersError, with: :render_conflicting_params_error

      private

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
