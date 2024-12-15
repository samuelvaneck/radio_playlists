# frozen_string_literal: true

# == Schema Information
#
# Table name: songs
#
#  id                     :bigint           not null, primary key
#  title                  :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  fullname               :text
#  spotify_song_url       :string
#  spotify_artwork_url    :string
#  id_on_spotify          :string
#  isrc                   :string
#  spotify_preview_url    :string
#  cached_chart_positions :jsonb
#

class Song < ApplicationRecord
  include GraphConcern
  include DateConcern

  has_many :artists_songs
  has_many :artists, through: :artists_songs
  has_many :playlists
  has_many :radio_station_songs, dependent: :destroy
  has_many :radio_stations, through: :radio_station_songs
  has_many :chart_positions, as: :positianable
  after_commit :update_fullname, on: %i[create update]

  scope :matching, lambda { |search_term|
    joins(:artists).where('title ILIKE ? OR artists.name ILIKE ?', "%#{search_term}%", "%#{search_term}%") if search_term
  }
  scope :with_iscr, ->(isrc) { where(isrc: isrc) }
  scope :with_id_on_spotify, -> { where.not(id_on_spotify: nil) }

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
                 songs.spotify_preview_url,
                 COUNT(DISTINCT playlists.id) AS COUNTER")
        .group(:id)
        .order('COUNTER DESC')
  end

  def self.most_played_group_by(column, params)
    most_played(params).group_by(&column)
  end

  def self.search_title(title)
    where('title ILIKE ?', "%#{title}%")
  end

  def cleanup
    destroy if playlists.blank?
    artists.each(&:cleanup)
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

  def self.find_and_remove_obsolete_songs
    Song.find_each do |song|
      song.find_and_remove_obsolete_song
    rescue StandardError => e
      Rails.logger.error("Song: #{song.id} - #{song.fullname}")
      Rails.logger.error("Error: #{e.message}")
      next
    end
  end
  
  def find_and_remove_obsolete_song
    songs = find_same_songs
    most_played_song = songs.max_by(&:played)
    songs = songs.reject { |song| song == most_played_song }
    return if [songs, most_played_song].flatten.count <= 1 || most_played_song.blank?

    Rails.logger.info("Removing absolute songs for #{most_played_song.fullname}")
    update_playlists_obsolete_songs(songs, most_played_song)
    cleanup_radio_station_songs(songs, most_played_song)
    remove_absolute_songs(songs)
  end

  def find_same_songs
    artist_ids = artists.pluck(:id)
    Song.joins(:artists).where(artists: { id: artist_ids }).where('lower(title) = ?', title.downcase)
  end

  def spotify_track
    return if id_on_spotify.blank?

    @spotify_track ||= Spotify::Track::FindById.new(id_on_spotify: id_on_spotify).execute
  end

  def update_chart_positions
    update(cached_chart_positions: ChartPosition.item_positions_with_date(self))
  end

  private

  def update_playlists_obsolete_songs(songs, most_played_song)
    Playlist.where(song: songs).update_all(song_id: most_played_song.id)
  end

  def remove_absolute_songs(songs)
    songs.each(&:cleanup)
  end

  def cleanup_radio_station_songs(songs, most_played_song)
    RadioStation.all.each do |radio_station|
      playlists = Playlist.where(song: [songs, most_played_song], radio_station:)
      next if playlists.blank?

      RadioStationSong.where(song: songs, radio_station:).delete_all

      rss = RadioStationSong.find_or_initialize_by(song: most_played_song, radio_station:)
      rss.first_broadcasted_at = playlists.minimum(:broadcasted_at)
      rss.save
    end
  end

  def update_fullname
    update_column(:fullname, "#{Array.wrap(artists).map(&:name).join(' ')} #{title}")
  end
end
