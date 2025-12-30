# frozen_string_literal: true

RSpec.configure do |config|
  config.around(with_valid_token: true) do |example|
    WebMock.enable!
    stub_request(:post, 'https://accounts.spotify.com/api/token').to_rack(FakeSpotify)
    example.run
    WebMock.disable!
  end

  # Stub Deezer and iTunes APIs by default to prevent test failures from enrichment callbacks
  config.before do
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
