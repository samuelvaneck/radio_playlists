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

class Artist < ApplicationRecord
  include PgSearch::Model
  include GraphConcern
  include DateConcern
  include ChartConcern
  include TimeAnalyticsConcern
  include ArtistSearchConcern
  include Sluggable

  pg_search_scope :search_by_name,
                  against: :name,
                  using: {
                    trigram: { threshold: 0.3, word_similarity: true },
                    tsearch: { prefix: true }
                  },
                  ranked_by: ':trigram + (0.25 * :tsearch) + (0.01 * COALESCE(artists.spotify_popularity, 0))'

  has_many :artists_songs
  has_many :songs, through: :artists_songs
  has_many :air_plays, through: :songs
  has_many :chart_positions, as: :positianable

  scope :matching, ->(search_term) { search_by_name(search_term).reorder(nil) if search_term.present? }

  before_create :set_slug
  after_commit :update_slug, on: [:update], if: :saved_change_to_name?

  validates :name, presence: true

  MOST_PLAYED_COLUMNS = %w[
    id name slug image
    id_on_spotify spotify_artist_url spotify_artwork_url spotify_popularity spotify_followers_count
    id_on_tidal tidal_artist_url
    id_on_deezer deezer_artist_url deezer_artwork_url
    id_on_itunes itunes_artist_url
    instagram_url website_url genres country_of_origin
    lastfm_listeners lastfm_playcount lastfm_tags
  ].map { |c| "artists.#{c}" }.freeze

  def self.most_played(params = {})
    start_time, end_time = time_range_from_params(params, default_period: 'week')

    Artist.joins(:air_plays)
      .merge(AirPlay.confirmed)
      .played_between(start_time, end_time)
      .played_on(params[:radio_station_ids])
      .matching(params[:search_term])
      .select(*MOST_PLAYED_COLUMNS, 'COUNT(DISTINCT air_plays.id) AS counter')
      .group(:id)
      .order('COUNTER DESC')
  end

  def self.most_played_group_by(column, params)
    most_played(params).group_by(&column)
  end

  def self.spotify_track_to_artist(track)
    track.artists.map do |track_artist|
      artist = Artist.find_or_initialize_by(id_on_spotify: track_artist['id']) || Artist.find_or_initialize_by(name: track_artist['name'])
      spotify_artwork_url = track_artist['images'][0]['url'] if track_artist['images'].present?
      artist.assign_attributes(
        name: track_artist['name'],
        spotify_artist_url: track_artist.dig('external_urls', 'spotify'),
        spotify_artwork_url:,
        id_on_spotify: track_artist['id']
      )
      artist.save
      artist
    end
  end

  def similar_artists(limit: 10)
    return Artist.none if genres.blank? && lastfm_tags.blank?

    Artist.where.not(id:)
      .where('genres && ARRAY[:genres]::varchar[] OR lastfm_tags && ARRAY[:tags]::varchar[]', genres:, tags: lastfm_tags)
      .select(
        'artists.*',
        "COALESCE(cardinality(ARRAY(SELECT unnest(genres) INTERSECT SELECT unnest(#{sanitized_sql_array(genres)}))), 0) + " \
        "COALESCE(cardinality(ARRAY(SELECT unnest(lastfm_tags) INTERSECT SELECT unnest(#{sanitized_sql_array(lastfm_tags)}))), 0) " \
        'AS similarity_score'
      )
      .order(Arel.sql('similarity_score DESC, COALESCE(spotify_popularity, 0) * 0.1 DESC'))
      .limit(limit)
  end

  def widget_data
    {
      total_played: air_plays.merge(AirPlay.confirmed).count,
      total_songs: songs.count,
      radio_stations_count: RadioStation.joins(radio_station_songs: { song: :artists_songs }).where(artists_songs: { artist_id: id }).distinct.count,
      country_of_origin: country_of_origin
    }
  end

  def cleanup
    destroy if songs.blank?
  end

  def played
    air_plays.size
  end

  def sanitized_sql_array(array)
    return 'ARRAY[]::varchar[]' if array.blank?

    "ARRAY[#{array.map { |element| ActiveRecord::Base.connection.quote(element) }.join(', ')}]"
  end

  def update_website_from_wikipedia
    return if website_url.present?

    official_website = Wikipedia::ArtistFinder.new.get_official_website(name)
    update(website_url: official_website) if official_website.present?
  end

  def fetch_aka_names
    MusicBrainz::ArtistAliasFetcher.new(self).()
  end

  def enrich_with_tidal
    Tidal::ArtistEnricher.new(self).enrich
  end

  def enrich_with_deezer
    Deezer::ArtistEnricher.new(self).enrich
  end

  def enrich_with_itunes
    Itunes::ArtistEnricher.new(self).enrich
  end

  def enrich_with_external_services
    enrich_with_tidal if should_enrich_with_tidal?
    enrich_with_deezer if should_enrich_with_deezer?
    enrich_with_itunes if should_enrich_with_itunes?
  end

  def needs_external_ids_enrichment?
    should_enrich_with_tidal? || should_enrich_with_deezer? || should_enrich_with_itunes?
  end

  private

  def should_enrich_with_tidal?
    id_on_tidal.blank? && name.present?
  end

  def should_enrich_with_deezer?
    id_on_deezer.blank? && name.present?
  end

  def should_enrich_with_itunes?
    id_on_itunes.blank? && name.present?
  end

  def slug_source
    name
  end
end
