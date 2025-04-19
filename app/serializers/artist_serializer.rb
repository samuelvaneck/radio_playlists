# frozen_string_literal: true

# == Schema Information
#
# Table name: artists
#
#  id                                :bigint           not null, primary key
#  name                              :string
#  image                             :string
#  genre                             :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  spotify_artist_url                :string
#  spotify_artwork_url               :string
#  id_on_spotify                     :string
#  cached_chart_positions            :jsonb
#  cached_chart_positions_updated_at :datetime
#
class ArtistSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :name, :spotify_artist_url, :spotify_artwork_url

  has_many :songs

  attribute :counter do |object|
    object.counter if object.respond_to?(:counter)
  end
end
