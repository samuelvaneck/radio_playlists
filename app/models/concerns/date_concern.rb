# frozen_string_literal: true

module DateConcern
  extend ActiveSupport::Concern

  included do
    def self.date_from_params(time:, fallback:)
      return fallback if time.blank?

      Time.zone.strptime(time, '%Y-%m-%dT%R')
    end
  end
end
