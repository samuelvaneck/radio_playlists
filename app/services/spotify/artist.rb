# frozen_string_literal: true

class Spotify::Artist < Spotify
  attr_reader :id_on_spotify

  def initialize(id_on_spotify)
    super
    @id_on_spotify = id_on_spotify
  end

  def info
    make_request(artist_url)
  end

  private

  def artist_url
    URI("https://api.spotify.com/v1/artists/#{@id_on_spotify}")
  end
end
