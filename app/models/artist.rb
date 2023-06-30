# frozen_string_literal: true

# == Schema Information
#
# Table name: artists
#
#  id                  :bigint           not null, primary key
#  name                :string
#  image               :string
#  genre               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  spotify_artist_url  :string
#  spotify_artwork_url :string
#  id_on_spotify       :string
#

class Artist < ApplicationRecord
  include GraphConcern

  has_many :artists_songs
  has_many :songs, through: :artists_songs
  has_many :playlists, through: :songs

  scope :matching, ->(search_term) { where!('artists.name ILIKE ?', "%#{search_term}%") if search_term.present? }

  validates :name, presence: true

  def self.most_played(params)
    Artist.joins(:playlists)
          .played_between(parsed_time(time: params[:start_time], fallback: 1.week.ago),
                          parsed_time(time: params[:end_time], fallback: Time.zone.now))
          .played_on(parsed_radio_station(params[:radio_station_id]))
          .matching(params[:search_term])
          .select("artists.id,
                   artists.name,
                   artists.image,
                   artists.id_on_spotify,
                   artists.spotify_artist_url,
                   artists.spotify_artwork_url,
                   COUNT(DISTINCT playlists.id) AS counter")
          .group(:id)
          .order('COUNTER DESC')
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
end
