# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Admin Radio Stations API', type: :request do
  let(:admin) { create(:admin) }
  let(:Authorization) { "Bearer #{jwt_token_for(admin)}" }

  path '/api/v1/admins/radio_stations' do
    get 'List radio stations for admin' do
      tags 'Admin Radio Stations'
      security [{ bearer_auth: [] }]
      produces 'application/json'

      response '200', 'Radio stations retrieved successfully' do
        let!(:radio_station) { create(:radio_station) }

        run_test!
      end

      response '401', 'Not authenticated' do
        let(:Authorization) { 'Bearer invalid_token' }

        run_test!
      end
    end
  end
end
