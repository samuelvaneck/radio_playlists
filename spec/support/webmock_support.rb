# frozen_string_literal: true

RSpec.configure do |config|
  config.around(with_valid_token: true) do |example|
    WebMock.enable!
    stub_request(:post, 'https://accounts.spotify.com/api/token').to_rack(FakeSpotify)
    example.run
    WebMock.disable!
  end

  # Stub Deezer and iTunes APIs by default to prevent test failures from enrichment callbacks
  # Skip for tests using VCR or real_http as they handle their own HTTP stubbing
  config.before do |example|
    next if example.metadata[:use_vcr] || example.metadata[:real_http]

    # Stub Deezer API - returns empty error response
    stub_request(:get, /api\.deezer\.com/).to_return(
      status: 200,
      body: { error: { type: 'DataException', message: 'no data', code: 800 } }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    # Stub iTunes API - returns empty results
    stub_request(:get, /itunes\.apple\.com/).to_return(
      status: 200,
      body: { resultCount: 0, results: [] }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end
end
