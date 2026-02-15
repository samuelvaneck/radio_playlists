# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Admin Authentication API', type: :request do
  path '/api/v1/admins/sign_in' do
    post 'Admin sign in' do
      tags 'Admin Authentication'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :admin, in: :body, schema: {
        type: :object,
        properties: {
          admin: {
            type: :object,
            properties: {
              email: { type: :string, format: :email },
              password: { type: :string }
            },
            required: %w[email password]
          }
        }
      }

      response '200', 'Logged in successfully' do
        let(:existing_admin) { create(:admin, password: 'password123') }
        let(:admin) { { admin: { email: existing_admin.email, password: 'password123' } } }

        run_test!
      end

      response '401', 'Authentication failed' do
        let(:admin) { { admin: { email: 'invalid@example.com', password: 'wrong' } } }

        run_test!
      end
    end
  end

  path '/api/v1/admins/sign_out' do
    delete 'Admin sign out' do
      tags 'Admin Authentication'
      security [{ bearer_auth: [] }]
      produces 'application/json'

      response '200', 'Logged out successfully' do
        let(:admin) { create(:admin) }
        let(:Authorization) { "Bearer #{jwt_token_for(admin)}" }

        run_test!
      end
    end
  end
end
