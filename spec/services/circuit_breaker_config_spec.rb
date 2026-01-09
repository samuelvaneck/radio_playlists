# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CircuitBreakerConfig do
  describe '.for' do
    it 'returns configuration for spotify', :aggregate_failures do
      config = described_class.for(:spotify)

      expect(config[:sleep_window]).to eq(30)
      expect(config[:volume_threshold]).to eq(10)
      expect(config[:error_threshold]).to eq(40)
      expect(config[:time_window]).to eq(60)
    end

    it 'returns configuration for itunes', :aggregate_failures do
      config = described_class.for(:itunes)

      expect(config[:sleep_window]).to eq(60)
      expect(config[:volume_threshold]).to eq(5)
      expect(config[:error_threshold]).to eq(50)
    end

    it 'returns configuration for deezer', :aggregate_failures do
      config = described_class.for(:deezer)

      expect(config[:sleep_window]).to eq(60)
      expect(config[:volume_threshold]).to eq(5)
      expect(config[:error_threshold]).to eq(50)
    end

    it 'returns configuration for youtube with longer sleep window', :aggregate_failures do
      config = described_class.for(:youtube)

      expect(config[:sleep_window]).to eq(120)
      expect(config[:volume_threshold]).to eq(3)
      expect(config[:error_threshold]).to eq(30)
    end

    it 'returns configuration for lastfm', :aggregate_failures do
      config = described_class.for(:lastfm)

      expect(config[:sleep_window]).to eq(90)
      expect(config[:volume_threshold]).to eq(5)
      expect(config[:error_threshold]).to eq(50)
    end

    it 'returns configuration for wikipedia', :aggregate_failures do
      config = described_class.for(:wikipedia)

      expect(config[:sleep_window]).to eq(60)
      expect(config[:volume_threshold]).to eq(5)
      expect(config[:error_threshold]).to eq(50)
    end

    it 'returns defaults for unknown service', :aggregate_failures do
      config = described_class.for(:unknown_service)

      expect(config[:sleep_window]).to eq(60)
      expect(config[:volume_threshold]).to eq(5)
      expect(config[:error_threshold]).to eq(50)
      expect(config[:time_window]).to eq(60)
    end
  end
end
