# frozen_string_literal: true

# == Schema Information
#
# Table name: artists
#
#  id                           :bigint           not null, primary key
#  country_of_origin            :string           default([]), is an Array
#  country_of_origin_checked_at :datetime
#  genres                       :string           default([]), is an Array
#  id_on_spotify                :string
#  image                        :string
#  instagram_url                :string
#  lastfm_enriched_at           :datetime
#  lastfm_listeners             :bigint
#  lastfm_playcount             :bigint
#  lastfm_tags                  :string           default([]), is an Array
#  name                         :string
#  slug                         :string
#  spotify_artist_url           :string
#  spotify_artwork_url          :string
#  spotify_followers_count      :integer
#  spotify_popularity           :integer
#  website_url                  :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#
# Indexes
#
#  index_artists_on_name_trgm  (name) USING gin
#  index_artists_on_slug       (slug) UNIQUE
#
class ArtistSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :name, :slug, :spotify_artist_url, :spotify_artwork_url, :instagram_url, :website_url, :genres,
             :spotify_popularity, :spotify_followers_count, :country_of_origin,
             :lastfm_listeners, :lastfm_playcount, :lastfm_tags

  has_many :songs

  attribute :counter do |object|
    object.counter if object.respond_to?(:counter)
  end
end
