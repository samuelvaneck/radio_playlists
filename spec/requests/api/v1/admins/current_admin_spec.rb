# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Current Admin API', type: :request do
  path '/api/v1/admins/current' do
    get 'Get current admin' do
      tags 'Admin'
      security [{ bearer_auth: [] }]
      produces 'application/json'

      response '200', 'Current admin retrieved successfully' do
        let(:admin) { create(:admin) }
        let(:Authorization) { "Bearer #{jwt_token_for(admin)}" }

        run_test!
      end

      response '401', 'Not authenticated' do
        let(:Authorization) { 'Bearer invalid_token' }

        run_test!
      end
    end
  end
end
