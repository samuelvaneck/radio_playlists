# frozen_string_literal: true

require 'sinatra/base'

class FakeSpotify < Sinatra::Base
  post '/api/token' do
    valid_token_response
  end

  private

  def valid_token_response
    content_type :json
    status 200
    body ({
      'access_token': 'BQADenodY_gAhAusZHnMChTTCWsvNmoqTg-poCMY8p3fsws1HQkhTh0UEsr7fpsSEr1avKoju2RqP6REwd4',
      'token_type': 'Bearer',
      'expires_in': 3600 }).to_json
  end
end
