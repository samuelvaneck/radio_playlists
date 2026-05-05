# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.filter_sensitive_data('<SPOTIFY_ACCESS_TOKEN>') do |interaction|
    next unless interaction.request.uri.include?('spotify')

    interaction.response.body[/"access_token":"([^"]+)"/, 1]
  end

  config.filter_sensitive_data('<SPOTIFY_BEARER_TOKEN>') do |interaction|
    next unless interaction.request.uri.include?('spotify')

    interaction.request.headers['Authorization']&.first&.match(/Bearer (.+)/)&.captures&.first
  end

  config.filter_sensitive_data('<SPOTIFY_BASIC_TOKEN>') do |interaction|
    next unless interaction.request.uri.include?('spotify')

    interaction.request.headers['Authorization']&.first&.match(/Basic (.+)/)&.captures&.first
  end

  config.filter_sensitive_data('<TIDAL_ACCESS_TOKEN>') do |interaction|
    next unless interaction.request.uri.include?('tidal')

    interaction.response.body[/"access_token":"([^"]+)"/, 1]
  end

  config.filter_sensitive_data('<TIDAL_BEARER_TOKEN>') do |interaction|
    next unless interaction.request.uri.include?('tidal')

    interaction.request.headers['Authorization']&.first&.match(/Bearer (.+)/)&.captures&.first
  end

  config.filter_sensitive_data('<TIDAL_BASIC_TOKEN>') do |interaction|
    next unless interaction.request.uri.include?('tidal')

    interaction.request.headers['Authorization']&.first&.match(/Basic (.+)/)&.captures&.first
  end

  config.filter_sensitive_data('<TIDAL_CLIENT_ID>') { ENV.fetch('TIDAL_CLIENT_ID', nil) }
  config.filter_sensitive_data('<TIDAL_CLIENT_SECRET>') { ENV.fetch('TIDAL_CLIENT_SECRET', nil) }
end

RSpec.configure do |config|
  config.around(use_vcr: true) do |example|
    options = {}
    options[:match_requests_on] = [:host, :path]
    path_data = [example.metadata[:description]]
    parent = example.example_group
    while parent != RSpec::ExampleGroups
      path_data << parent.metadata[:description]
      parent = parent.module_parent
    end
    cassette_name = path_data.map { |str| str.underscore.gsub(/\./, '').gsub(%r{[^\w/]+}, '_').gsub(%r{/$}, '') }.reverse.join('/')
    WebMock.enable!
    VCR.turn_on!
    VCR.use_cassette(cassette_name, options) do
      example.run
    end
    WebMock.enable!
    VCR.turn_off!
  end

  config.around(real_http: true) do |example|
    WebMock.reset!
    WebMock.disable!
    VCR.turn_off!
    example.run
    WebMock.enable!
    VCR.turn_off!
  end

  config.prepend_before(:context) do
    WebMock.enable!
    VCR.turn_off!
  end

  config.append_after(:context) do
    WebMock.enable!
    VCR.turn_off!
  end
end
