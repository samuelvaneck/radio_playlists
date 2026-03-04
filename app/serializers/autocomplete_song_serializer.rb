# frozen_string_literal: true

class AutocompleteSongSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :title,
             :spotify_artwork_url

  attribute :artists do |object|
    object.artists.map { |artist| { id: artist.id, name: artist.name } }
  end

  attribute :in_chart do |object, params|
    params.dig(:chart_data, object.id, :in_chart)
  end

  attribute :last_chart_date do |object, params|
    params.dig(:chart_data, object.id, :last_chart_date)
  end
end
