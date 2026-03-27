# frozen_string_literal: true

require 'rails_helper'

describe 'Rate limiting configuration', type: :request do
  def rate_limit_callbacks(controller_class)
    controller_class._process_action_callbacks.select do |cb|
      cb.filter.is_a?(Proc) && cb.filter.source_location&.first&.include?('rate_limiting')
    end
  end

  def rate_limit_name(callback)
    callback.filter.binding.local_variable_get(:name)
  end

  describe 'each rate limit has a unique name to prevent cache key collisions' do
    it 'names the general API rate limit' do
      callback = rate_limit_callbacks(Api::V1::ApiController).first

      expect(rate_limit_name(callback)).to eq('general')
    end

    it 'names the stream_proxy rate limit' do
      callbacks = rate_limit_callbacks(Api::V1::RadioStationsController)
      stream_proxy_callback = callbacks.find { |cb| rate_limit_name(cb) == 'stream-proxy' }

      expect(stream_proxy_callback).to be_present
    end

    it 'names the classifiers rate limit' do
      callbacks = rate_limit_callbacks(Api::V1::RadioStationClassifiersController)
      classifiers_callback = callbacks.find { |cb| rate_limit_name(cb) == 'classifiers' }

      expect(classifiers_callback).to be_present
    end

    it 'has no unnamed rate limits across API controllers' do
      controllers = [
        Api::V1::ApiController,
        Api::V1::RadioStationsController,
        Api::V1::RadioStationClassifiersController
      ]

      unnamed = controllers.flat_map { |c| rate_limit_callbacks(c) }.select { |cb| rate_limit_name(cb).nil? }

      expect(unnamed).to be_empty
    end
  end
end
