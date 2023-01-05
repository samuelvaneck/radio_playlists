# frozen_string_literal: true

class Isrc::Ifpi < Isrc
  ENDPOINT = 'https://isrcsearch.ifpi.org'

  attr_reader :title, :artist_name

  def initialize(args = {})
    @args = args
  end

  def make_request
    authorize
    search
  end

  def authorize
    url = URI(ENDPOINT)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request['Host'] = 'isrcsearch.ifpi.org'
    response = https.request(request)
    @cookies = parse_cookies(response['set-cookie'])
    @csrf_token = @cookies['csrftoken']
    @session_id = @cookies['Secure, sessionid']
    @x_csrf_token = set_x_csrf_token(response.body)
  end

  def search
    url = URI("#{ENDPOINT}/api/v1/search")

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request['content-type'] = 'application/json;charset=UTF-8'
    request['cookie'] = "csrftoken=#{@csrf_token}; sessionid=#{@session_id};"
    request['origin'] = ENDPOINT
    request['referer'] = ENDPOINT
    request['sec-fetch-mode'] = 'cors'
    request['sec-fetch-site'] = 'same-origin'
    request['x-csrftoken'] = @x_csrf_token
    body = {
      'searchFields':
          {
              'isrcCode': 'USUG12205736'
          },
      'showReleases': false,
      'start': 0,
      'number': 1
    }.to_json
    request.body = body
    response = https.request(request)
  end

  private

  def parse_cookies(cookies)
    result = {}
    cookies.split(';').each do |cookie|
      key, value = cookie.split('=')
      result[key.strip] = value
    end
    result
  end

  def set_x_csrf_token(body)
    doc = Nokogiri::HTML(body)
    tag = doc.search('script')[5]
    tag.content.match(/csrfmiddlewaretoken = "(?<csrf_token>.*?)"/)[:csrf_token]
  end
end
