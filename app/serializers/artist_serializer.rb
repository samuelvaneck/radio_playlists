# frozen_string_literal: true

# == Schema Information
#
# Table name: artists
#
#  id                                :bigint           not null, primary key
#  cached_chart_positions            :jsonb
#  cached_chart_positions_updated_at :datetime
#  genre                             :string
#  id_on_spotify                     :string
#  image                             :string
#  instagram_url                     :string
#  name                              :string
#  spotify_artist_url                :string
#  spotify_artwork_url               :string
#  website_url                       :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#
# Indexes
#
#  index_artists_on_name  (name)
#
class ArtistSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :name, :spotify_artist_url, :spotify_artwork_url, :instagram_url, :website_url

  has_many :songs

  attribute :counter do |object|
    object.counter if object.respond_to?(:counter)
  end
end
