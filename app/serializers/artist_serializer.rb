# frozen_string_literal: true

# == Schema Information
#
# Table name: artists
#
#  id                           :bigint           not null, primary key
#  aka_names                    :string           default([]), is an Array
#  aka_names_checked_at         :datetime
#  country_of_origin            :string           default([]), is an Array
#  country_of_origin_checked_at :datetime
#  deezer_artist_url            :string
#  deezer_artwork_url           :string
#  genres                       :string           default([]), is an Array
#  id_on_deezer                 :string
#  id_on_itunes                 :string
#  id_on_musicbrainz            :string
#  id_on_spotify                :string
#  id_on_tidal                  :string
#  image                        :string
#  instagram_url                :string
#  itunes_artist_url            :string
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
#  tidal_artist_url             :string
#  website_url                  :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#
# Indexes
#
#  index_artists_on_aka_names          (aka_names) USING gin
#  index_artists_on_id_on_deezer       (id_on_deezer)
#  index_artists_on_id_on_itunes       (id_on_itunes)
#  index_artists_on_id_on_musicbrainz  (id_on_musicbrainz) UNIQUE
#  index_artists_on_id_on_tidal        (id_on_tidal)
#  index_artists_on_name_trgm          (name) USING gin
#  index_artists_on_slug               (slug) UNIQUE
#
class ArtistSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :name, :slug, :spotify_artist_url, :spotify_artwork_url, :instagram_url, :website_url, :genres,
             :spotify_popularity, :spotify_followers_count, :country_of_origin,
             :lastfm_listeners, :lastfm_playcount, :lastfm_tags,
             :id_on_tidal, :tidal_artist_url,
             :id_on_deezer, :deezer_artist_url, :deezer_artwork_url,
             :id_on_itunes, :itunes_artist_url

  has_many :songs

  attribute :counter do |object|
    object.counter if object.respond_to?(:counter)
  end
end
