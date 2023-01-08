# frozen_string_literal: true

require 'uri'
require 'net/http'

class Isrc
  attr_reader :title, :artist_names, :isrc_code

  def initialize(args = {})
    @args = args
  end

  def make_request(args = {})
    method = args[:method] || 'get'
    https = Net::HTTP.new(args[:url].host, args[:url].port)
    https.use_ssl = true
    request = if method == 'get'
                Net::HTTP::Get.new(args[:url], args[:headers])
              else
                Net::HTTP::Post.new(args[:url], args[:headers])
              end
    request.body = request_body if method == 'post'
    https.request(request)
  end
end
