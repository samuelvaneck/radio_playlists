# frozen_string_literal: true

# == Schema Information
#
# Table name: artists
#
#  id                 :bigint           not null, primary key
#  genre              :string
#  id_on_spotify      :string
#  image              :string
#  instagram_url      :string
#  name               :string
#  spotify_artist_url :string
#  spotify_artwork_url:string
#  website_url        :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_artists_on_name  (name)
#

class Artist < ApplicationRecord
  include GraphConcern
  include DateConcern
  include ChartConcern
  include TimeAnalyticsConcern

  has_many :artists_songs
  has_many :songs, through: :artists_songs
  has_many :air_plays, through: :songs
  has_many :chart_positions, as: :positianable

  scope :matching, ->(search_term) { where!('artists.name ILIKE ?', "%#{search_term}%") if search_term.present? }

  validates :name, presence: true

  def self.most_played(params = {})
    Artist.joins(:air_plays)
          .played_between(date_from_params(time: params[:start_time], fallback: 1.week.ago),
                          date_from_params(time: params[:end_time], fallback: Time.zone.now))
          .played_on(params[:radio_station_ids])
          .matching(params[:search_term])
          .select("artists.id,
                   artists.name,
                   artists.image,
                   artists.id_on_spotify,
                   artists.spotify_artist_url,
                   artists.spotify_artwork_url,
                   artists.instagram_url,
                   artists.website_url,
                   COUNT(DISTINCT air_plays.id) AS counter")
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

  def cleanup
    destroy if songs.blank?
  end

  def played
    air_plays.size
  end

  def update_website_from_wikipedia
    return if website_url.present?

    official_website = Wikipedia::ArtistFinder.new.get_official_website(name)
    update(website_url: official_website) if official_website.present?
  end
end
