# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientTokenGenerator do
  let(:client_id) { 'test-client-id' }
  let(:secret) { 'test-secret' }

  before { ENV['FRONTEND_JWT_SECRET'] = secret }

  after { ENV.delete('FRONTEND_JWT_SECRET') }

  describe '#call' do
    it 'returns a valid JWT token', :aggregate_failures do
      token = described_class.new(client_id).()
      decoded = JWT.decode(token, secret, true, algorithm: 'HS256').first

      expect(decoded['client_id']).to eq(client_id)
      expect(decoded['exp']).to be_within(5).of(10.minutes.from_now.to_i)
      expect(decoded['iat']).to be_within(5).of(Time.current.to_i)
    end
  end
end
