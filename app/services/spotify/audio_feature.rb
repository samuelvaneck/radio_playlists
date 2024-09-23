module Spotify
  class AudioFeature < Base
    def get_audio_features
      make_request(url)
    end

    private

    def url
      URI("https://api.spotify.com/v1/audio-features/#{args[:id_on_spotify]}")
    end
  end
end
