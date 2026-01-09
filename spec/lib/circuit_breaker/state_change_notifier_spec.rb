# frozen_string_literal: true

require 'rails_helper'
require 'circuit_breaker/state_change_notifier'

RSpec.describe CircuitBreaker::StateChangeNotifier do
  subject(:notifier) { described_class.new }

  describe '#notify' do
    context 'when event is :open' do
      before do
        allow(Rails.logger).to receive(:error)
        allow(NewRelic::Agent).to receive(:record_custom_event)
      end

      it 'logs the state change at error level' do
        notifier.notify(:test_circuit, :open)
        expect(Rails.logger).to have_received(:error).with(/test_circuit state changed to open/)
      end

      it 'sends event to NewRelic' do
        notifier.notify(:test_circuit, :open)
        expect(NewRelic::Agent).to have_received(:record_custom_event).with(
          'CircuitBreakerStateChange',
          hash_including(circuit_name: 'test_circuit', state: 'open')
        )
      end
    end

    context 'when event is :close' do
      before do
        allow(Rails.logger).to receive(:info)
        allow(NewRelic::Agent).to receive(:record_custom_event)
      end

      it 'logs the state change at info level' do
        notifier.notify(:test_circuit, :close)
        expect(Rails.logger).to have_received(:info).with(/test_circuit state changed to closed/)
      end

      it 'sends event to NewRelic' do
        notifier.notify(:test_circuit, :close)
        expect(NewRelic::Agent).to have_received(:record_custom_event).with(
          'CircuitBreakerStateChange',
          hash_including(circuit_name: 'test_circuit', state: 'closed')
        )
      end
    end

    context 'when event is :half_open' do
      before { allow(Rails.logger).to receive(:info) }

      it 'logs the state change at info level' do
        notifier.notify(:test_circuit, :half_open)
        expect(Rails.logger).to have_received(:info).with(/test_circuit state changed to half_open/)
      end
    end

    context 'when event is :failure' do
      before { allow(Rails.logger).to receive(:warn) }

      it 'logs failure at warn level' do
        notifier.notify(:test_circuit, :failure)
        expect(Rails.logger).to have_received(:warn).with(/test_circuit: failure recorded/)
      end
    end

    context 'when event is :skipped' do
      before { allow(Rails.logger).to receive(:warn) }

      it 'logs skipped request at warn level' do
        notifier.notify(:test_circuit, :skipped)
        expect(Rails.logger).to have_received(:warn).with(/test_circuit: request skipped/)
      end
    end

    context 'when event is :success' do
      before { allow(Rails.logger).to receive(:debug) }

      it 'logs at debug level' do
        notifier.notify(:test_circuit, :success)
        expect(Rails.logger).to have_received(:debug)
      end
    end

    context 'when NewRelic fails' do
      before do
        allow(Rails.logger).to receive(:error)
        allow(NewRelic::Agent).to receive(:record_custom_event).and_raise(StandardError, 'NewRelic error')
      end

      it 'logs the error and does not raise', :aggregate_failures do
        expect { notifier.notify(:test_circuit, :open) }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(/Failed to send to NewRelic/)
      end
    end
  end
end
