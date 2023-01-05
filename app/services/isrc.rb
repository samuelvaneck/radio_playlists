# frozen_string_literal: true

require 'uri'
require 'net/http'

class Isrc
  attr_reader :title, :artist_names

  def initialize(args = {})
    @args = args
  end
end
