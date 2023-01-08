# frozen_string_literal: true

class Isrc::Ifpi < Isrc
  ENDPOINT = 'https://isrcsearch.ifpi.org'

  def initialize(args = {})
    super
    authorize
  end

  def data
    url = URI("#{ENDPOINT}/api/v1/search")
    response = make_request(url:, headers: request_headers, method: 'post')
    handle_response(response)
  end

  private

  def authorize
    url = URI(ENDPOINT)
    response = make_request(url:, headers: authorization_headers)
    @cookies = parse_cookies(response['set-cookie'])
    @csrf_token = @cookies['csrftoken']
    @session_id = @cookies['Secure, sessionid']
    @x_csrf_token = x_csrf_token(response.body)
  end

  def parse_cookies(cookies)
    result = {}
    cookies.split(';').each do |cookie|
      key, value = cookie.split('=')
      result[key.strip] = value
    end
    result
  end

  def x_csrf_token(body)
    doc = Nokogiri::HTML(body)
    tag = doc.search('script')[5]
    tag.content.match(/csrfmiddlewaretoken = "(?<csrf_token>.*?)"/)[:csrf_token]
  end

  def authorization_headers
    headers = {}
    headers['Host'] = 'isrcsearch.ifpi.org'
    headers
  end

  def request_headers
    headers = {}
    headers['content-type'] = 'application/json;charset=UTF-8'
    headers['cookie'] = "csrftoken=#{@csrf_token}; sessionid=#{@session_id};"
    headers['origin'] = ENDPOINT
    headers['referer'] = ENDPOINT
    headers['sec-fetch-mode'] = 'cors'
    headers['sec-fetch-site'] = 'same-origin'
    headers['x-csrftoken'] = @x_csrf_token
    headers
  end

  def request_body
    {
      'searchFields': request_body_search_fields,
      'showReleases': false,
      'start': 0,
      'number': 1
    }.to_json
  end

  def request_body_search_fields
    fields = {}
    fields[:isrcCode] = @args[:isrc_code] if @args[:isrc_code].present?
    fields[:trackTitle] = @args[:title] if @args[:title].present?
    fields[:artistName] = @args[:artist_name] if @args[:artist_name].present?
    fields
  end

  def handle_response(response)
    if response.code == '200'
      data = JSON.parse(response.body).with_indifferent_access
      return false if data[:displayDocs].blank?

      track = data.dig(:displayDocs, 0)
      @title = track[:trackTitle]
      @title += " (#{track[:recordingVersion]})" if track[:recordingVersion].present?
      @artist_names = track[:artistName]
      @isrc_code = track[:id]
      true
    else
      Rails.logger.error(response.try(:body))
      false
    end
  end
end
