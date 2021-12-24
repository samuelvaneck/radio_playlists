# frozen_string_literal: true

# RSpec.configure do |config|
#   config.around(with_valid_token: true) do |example|
#     WebMock.enable!
#     stub_request(:post, 'https://accounts.spotify.com/api/token').to_rack(FakeSpotify)
#     example.run
#     WebMock.disable!
#   end
# end
