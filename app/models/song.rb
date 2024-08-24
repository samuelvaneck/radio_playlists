# frozen_string_literal: true

# == Schema Information
#
# Table name: songs
#
#  id                  :bigint           not null, primary key
#  title               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  fullname            :text
#  spotify_song_url    :string
#  spotify_artwork_url :string
#  id_on_spotify       :string
#  isrc                :string
#

class Song < ApplicationRecord
  include GraphConcern
  include DateConcern

  has_many :artists_songs
  has_many :artists, through: :artists_songs
  has_many :playlists
  has_many :radio_station_songs
  has_many :radio_stations, through: :radio_station_songs
  after_commit :update_fullname, on: %i[create update]

  scope :matching, lambda { |search_term|
    joins(:artists).where('title ILIKE ? OR artists.name ILIKE ?', "%#{search_term}%", "%#{search_term}%") if search_term
  }
  scope :with_iscr, ->(isrc) { where(isrc: isrc) }

  MULTIPLE_ARTIST_REGEX = ';|\bfeat\.|\bvs\.|\bft\.|\bft\b|\bfeat\b|\bft\b|&|\bvs\b|\bversus|\band\b|\bmet\b|\b,|\ben\b|\/'
  ARTISTS_FILTERS = ['karoke', 'cover', 'made famous', 'tribute', 'backing business', 'arcade', 'instrumental', '8-bit', '16-bit'].freeze
  public_constant :MULTIPLE_ARTIST_REGEX
  public_constant :ARTISTS_FILTERS

  def self.most_played(params)
    Song.joins(:playlists, :artists)
        .played_between(date_from_params(time: params[:start_time], fallback: 1.week.ago),
                        date_from_params(time: params[:end_time], fallback: Time.zone.now))
        .played_on(params[:radio_station_ids])
        .matching(params[:search_term])
        .select("songs.id,
                 songs.title,
                 songs.fullname,
                 songs.id_on_spotify,
                 songs.spotify_song_url,
                 songs.spotify_artwork_url,
                 COUNT(DISTINCT playlists.id) AS COUNTER")
        .group(:id)
        .order('COUNTER DESC')
  end

  def self.search_title(title)
    where('title ILIKE ?', "%#{title}%")
  end

  def cleanup
    destroy if playlists.blank?
    artists.each(&:cleanup)
  end

  def self.find_and_remove_absolute_songs
    Song.all.each do |song|
      songs = song.find_same_songs
      most_played_song = songs.max_by(&:played)
      next if songs.count <= 1 || most_played_song.blank?

      remove_absolute_songs(songs, most_played_song)
    end
  end

  def update_artists(song_artists)
    crumb = Sentry::Breadcrumb.new(
      category: 'import_song',
      data: { song_id: id, song_title: title, song_artists: song_artists },
      level: 'info'
    )
    Sentry.add_breadcrumb(crumb)
    self.artists = Array.wrap(song_artists) if song_artists.present?
  end

  def played
    playlists.size
  end

  def find_same_songs
    artist_ids = artists.pluck(:id)
    Song.joins(:artists).where(artists: { id: artist_ids }).where('lower(title) = ?', title.downcase)
  end

  private

  def remove_absolute_songs(songs, most_played_song)
    songs.each do |song|
      next if song.id == most_played_song.id

      Playlist.where(song: song).each do |playlist|
        playlist.update_column(:song_id, most_played_song.id)
      end
      RadioStation.each do |radio_station|
        playlists = Playlist.where(song: [song, most_played_song], radio_station:)
        most_played_song_radio_station = RadioStationSong.find_by(song: most_played_song, radio_station:)
        most_played_song_radio_station.update_column(
          :first_broadcasted_at,
          playlists.minimum(:broadcasted_at)
        )
        RadioStationSong.where(song: song, radio_station:).destroy_all
      end
      song.cleanup
    end
  end

  def update_fullname
    update_column(:fullname, "#{Array.wrap(artists).map(&:name).join(' ')} #{title}")
  end
end
