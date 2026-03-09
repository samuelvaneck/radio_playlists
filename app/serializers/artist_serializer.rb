# frozen_string_literal: true

# == Schema Information
#
# Table name: artists
#
#  id                      :bigint           not null, primary key
#  country_of_origin       :string           default([]), is an Array
#  genres                  :string           default([]), is an Array
#  id_on_spotify           :string
#  image                   :string
#  instagram_url           :string
#  lastfm_enriched_at      :datetime
#  lastfm_listeners        :bigint
#  lastfm_playcount        :bigint
#  lastfm_tags             :string           default([]), is an Array
#  name                    :string
#  spotify_artist_url      :string
#  spotify_artwork_url     :string
#  spotify_followers_count :integer
#  spotify_popularity      :integer
#  website_url             :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_artists_on_name_trgm  (name) USING gin
#
class ArtistSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :name, :spotify_artist_url, :spotify_artwork_url, :instagram_url, :website_url, :genres,
             :spotify_popularity, :spotify_followers_count, :country_of_origin,
             :lastfm_listeners, :lastfm_playcount, :lastfm_tags

  has_many :songs

  attribute :counter do |object|
    object.counter if object.respond_to?(:counter)
  end
end
