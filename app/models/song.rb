# frozen_string_literal: true

# == Schema Information
#
# Table name: songs
#
#  id                                :bigint           not null, primary key
#  cached_chart_positions            :jsonb
#  cached_chart_positions_updated_at :datetime
#  id_on_spotify                     :string
#  id_on_youtube                     :string
#  isrc                              :string
#  search_text                       :text
#  spotify_artwork_url               :string
#  spotify_preview_url               :string
#  spotify_song_url                  :string
#  title                             :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#
# Indexes
#
#  index_songs_on_search_text  (search_text)
#

class Song < ApplicationRecord
  include GraphConcern
  include DateConcern
  include ChartConcern

  has_many :artists_songs
  has_many :artists, through: :artists_songs
  has_many :playlists
  has_many :radio_station_songs, dependent: :destroy
  has_many :radio_stations, through: :radio_station_songs
  has_many :chart_positions, as: :positianable

  before_create :set_search_text
  after_commit :update_search_text, on: [:update], if: :saved_change_to_title?

  scope :matching, lambda { |search_term|
    where('songs.search_text ILIKE ?', "%#{search_term}%") if search_term.present?
  }
  scope :with_iscr, ->(isrc) { where(isrc: isrc) }
  scope :with_id_on_spotify, -> { where.not(id_on_spotify: nil) }

  MULTIPLE_ARTIST_REGEX = ';|\bfeat\.|\bvs\.|\bft\.|\bft\b|\bfeat\b|\bft\b|&|\bvs\b|\bversus|\band\b|\bmet\b|\b,|\ben\b|\/'
  ARTISTS_FILTERS = ['karoke', 'cover', 'made famous', 'tribute', 'backing business', 'arcade', 'instrumental', '8-bit', '16-bit'].freeze
  public_constant :MULTIPLE_ARTIST_REGEX
  public_constant :ARTISTS_FILTERS

  def self.most_played(params = {})
    Song.joins(:playlists)
        .played_between(date_from_params(time: params[:start_time], fallback: 1.week.ago),
                        date_from_params(time: params[:end_time], fallback: Time.zone.now))
        .played_on(params[:radio_station_ids])
        .matching(params[:search_term])
        .select("songs.id,
                 songs.title,
                 songs.search_text,
                 songs.id_on_spotify,
                 songs.spotify_song_url,
                 songs.spotify_artwork_url,
                 songs.spotify_preview_url,
                 songs.id_on_youtube,
                 COUNT(DISTINCT playlists.id) AS COUNTER")
        # .from('songs')
        .group('songs.id, songs.title')
        .order('COUNTER DESC')
  end

  def self.most_played_group_by(column, params)
    most_played(params).group_by(&column)
  end

  def self.search(search_term)
    where('search_text ILIKE ?', "%#{search_term}%")
  end

  def cleanup
    destroy if playlists.blank?
    artists.each(&:cleanup)
  end

  def update_artists(song_artists)
    return if song_artists.blank?

    self.artists = Array.wrap(song_artists)
    update_search_text
  end

  def played
    playlists.size
  end

  def self.find_and_remove_obsolete_songs
    Song.find_each do |song|
      song.find_and_remove_obsolete_song
    rescue StandardError => e
      Rails.logger.error("Song: #{song.id} - #{song.search_text}. Error: #{e.message}")
      next
    end
  end

  def find_and_remove_obsolete_song
    songs = find_same_songs
    most_played_song = songs.max_by(&:played)
    songs = songs.reject { |song| song == most_played_song }
    return if [songs, most_played_song].flatten.count <= 1 || most_played_song.blank?

    Rails.logger.info("Removing absolute songs for #{most_played_song.search_text}")
    update_playlists_obsolete_songs(songs, most_played_song)
    cleanup_radio_station_songs(songs, most_played_song)
    remove_absolute_songs(songs)
  end

  def find_same_songs
    artist_ids = artists.pluck(:id)
    Song.joins(:artists).where(artists: { id: artist_ids }).where('lower(title) = ?', title&.downcase)
  end

  def spotify_track
    return if id_on_spotify.blank?

    @spotify_track ||= Spotify::Track::FindById.new(id_on_spotify: id_on_spotify).execute
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

  def set_search_text
    return if search_text.present?

    self.search_text = "#{artists.map(&:name).join(' ')} #{title}"
  end

  def update_search_text
    update_column(:search_text, "#{artists.pluck(:name).join(' ')} #{title}")
  end
end
