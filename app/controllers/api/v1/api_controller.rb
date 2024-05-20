# frozen_string_literal: true

module Api
  module V1
    class ApiController < ActionController::Base
      # Prevent CSRF attacks by raising an exception.
      # For APIs, you may want to use :null_session instead
      protect_from_forgery with: :null_session

      private

      def pagination_data(items)
        return {} if items.blank?

        { total_entries: items.total_entries || 0, total_pages: items.total_pages || 0, current_page: items.current_page }
      end
    end
  end
end
