# frozen_string_literal: true

require 'sinatra/base'

class FakeSpotify < Sinatra::base
  post '/api/token' do
    valid_token_response
  end

  private

  def valid_token_response
    content_type :json
    status 200
    body (
      'access_token': 'NgCXRKc...MzYjw',
      'token_type': 'Bearer',
      'expires_in': 3600
    ).to_json
  end
end
