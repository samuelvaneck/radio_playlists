# frozen_string_literal: true

class AutocompleteSongSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :title,
             :spotify_artwork_url

  attribute :artists do |object|
    object.artists.map { |artist| { id: artist.id, name: artist.name } }
  end

end
