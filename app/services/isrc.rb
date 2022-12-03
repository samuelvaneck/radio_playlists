# frozen_string_literal: true

require 'uri'
require 'net/http'

class Isrc
  ENDPOINT = 'https://isrcsearch.ifpi.org/api/v1/search'

  attr_reader :title, :artist_name

  def initialize(args = {})
    @args = args
  end

  def search
    make_request
  end

  def make_request
    url = URI(ENDPOINT)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request['content-type'] = 'application/json;charset=UTF-8'
    request['cookie'] = "_ga=GA1.2.61660241.1668346333; csrftoken=#{ENV['ISRC_SESSION_CSRF_TOKEN']}; sessionid=#{ENV['ISRC_SESSION_ID']};; sessionid=#{ENV['ISRC_SESSION_ID']}"
    request['origin'] = 'https://isrcsearch.ifpi.org'
    request['referer'] = 'https://isrcsearch.ifpi.org/'
    request['sec-fetch-mode'] = 'cors'
    request['sec-fetch-site'] = 'same-origin'
    request['x-csrftoken'] = ENV['ISRC_X_CSRF_TOKEN']
    request.body = request_body
    response = https.request(request)

    handle_response(response)
  end

  def request_body
    {
      'searchFields':
        {
          'isrcCode': @args[:isrc_code]
        },
      'showReleases': false,
      'start': 0,
      'number': 1
    }.to_json
  end

  def handle_response(response)
    if response.try(:code) == '200'
      @title = JSON(response.read_body)['displayDocs'][0]['trackTitle']
      @artist_name = JSON(response.read_body)['displayDocs'][0]['artistName']
      true
    else
      Rails.logger.error JSON(response.read_body)
      false
    end
  end
end
