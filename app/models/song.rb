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
  has_many :radio_stations, through: :playlists
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
    Song.joins(:playlists)
        .played_between(date_from_params(time: params[:start_time], fallback: 1.week.ago),
                        date_from_params(time: params[:end_time], fallback: Time.zone.now))
        .played_on(params[:radio_station_id])
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
      songs = find_same_songs(song)
      correct_song = songs.last
      next if songs.count <= 1 || correct_song.blank?

      remove_absolute_songs(songs, correct_song)
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

  private

  def find_same_songs(song)
    artist_ids = song.artists.map(&:id)
    Song.joins(:artists).where(artists: { id: artist_ids }).where('lower(title) = ?', song.title.downcase)
  end

  def remove_absolute_songs(songs, correct_song)
    songs.map(&:id).each do |id|
      next if id == correct_song.id

      absolute_song = Song.find(id) rescue next
      gps = Playlist.where(song: absolute_song)
      gps.each { |gp| gp.update_attribute('song_id', correct_song.id) }
      absolute_song.cleanup
    end
  end

  def update_fullname
    update_column(:fullname, "#{Array.wrap(artists).map(&:name).join(' ')} #{title}")
  end
end
