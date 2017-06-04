require 'rspotify/oauth'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :spotify, "ff70df650ee14a1fad4aed3b533e8ea4", "9899f570bc3e4781b9373e60d6f37095", scope: 'user-read-email playlist-modify-public user-library-read user-library-modify'
end
