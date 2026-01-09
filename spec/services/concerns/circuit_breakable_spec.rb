# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CircuitBreakable do
  let(:test_class) do
    Class.new do
      include CircuitBreakable
      circuit_breaker_for :test_service

      def call_external(&block)
        with_circuit_breaker(&block)
      end

      def call_with_backoff(&)
        with_exponential_backoff(max_attempts: 3, base_delay: 0.01, &)
      end

      def check_rate_limit(response)
        handle_rate_limit_response(response)
      end
    end
  end

  let(:instance) { test_class.new }

  before do
    allow(CircuitBreakerConfig).to receive(:for).with(:test_service).and_return({
                                                                                  sleep_window: 60,
                                                                                  volume_threshold: 2,
                                                                                  error_threshold: 50,
                                                                                  time_window: 10
                                                                                })
  end

  describe '#with_circuit_breaker' do
    context 'when circuit is closed' do
      it 'executes the block' do
        result = instance.call_external { 'success' }
        expect(result).to eq('success')
      end
    end

    context 'when block raises exception' do
      it 'propagates the exception wrapped in ServiceFailureError' do
        expect do
          instance.call_external { raise Faraday::Error, 'test error' }
        end.to raise_error(Circuitbox::ServiceFailureError)
      end
    end
  end

  describe '#with_exponential_backoff' do
    it 'retries with increasing delays', :aggregate_failures do
      attempts = 0
      result = instance.call_with_backoff do
        attempts += 1
        raise Faraday::Error, 'test' if attempts < 3

        'success'
      end

      expect(result).to eq('success')
      expect(attempts).to eq(3)
    end

    it 'raises after max attempts' do
      expect do
        instance.call_with_backoff { raise Faraday::Error, 'persistent error' }
      end.to raise_error(Faraday::Error)
    end
  end

  describe '#handle_rate_limit_response' do
    let(:rate_limited_response) do
      instance_double(Faraday::Response, status: 429, headers: { 'Retry-After' => '60' })
    end

    let(:ok_response) do
      instance_double(Faraday::Response, status: 200, headers: {})
    end

    it 'raises RateLimitError on 429 response' do
      expect do
        instance.check_rate_limit(rate_limited_response)
      end.to raise_error(CircuitBreakable::RateLimitError)
    end

    it 'does not raise on successful response' do
      expect do
        instance.check_rate_limit(ok_response)
      end.not_to raise_error
    end
  end

  describe 'CircuitOpenError' do
    it 'includes service name', :aggregate_failures do
      error = CircuitBreakable::CircuitOpenError.new(:test_service)
      expect(error.service_name).to eq(:test_service)
      expect(error.message).to include('test_service')
    end
  end

  describe 'RateLimitError' do
    it 'includes retry_after value', :aggregate_failures do
      error = CircuitBreakable::RateLimitError.new(60)
      expect(error.retry_after).to eq(60)
      expect(error.message).to include('60')
    end
  end
end
