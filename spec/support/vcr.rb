# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock
end

RSpec.configure do |config|
  config.around(:example, use_vcr: true) do |example|
    options = {}
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

  config.around(:example, real_http: true) do |example|
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
