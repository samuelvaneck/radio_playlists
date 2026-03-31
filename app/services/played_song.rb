# frozen_string_literal: true

PlayedSong = Data.define(:artist_name, :title, :broadcasted_at, :spotify_url, :isrc_code) do
  def initialize(artist_name:, title:, broadcasted_at:, spotify_url: nil, isrc_code: nil)
    super
  end
end
