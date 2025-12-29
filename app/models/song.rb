# frozen_string_literal: true

# == Schema Information
#
# Table name: songs
#
#  id                     :bigint           not null, primary key
#  id_on_spotify          :string
#  id_on_youtube          :string
#  isrc                   :string
#  release_date           :date
#  release_date_precision :string
#  search_text            :text
#  spotify_artwork_url    :string
#  spotify_preview_url    :string
#  spotify_song_url       :string
#  title                  :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_songs_on_release_date  (release_date)
#  index_songs_on_search_text   (search_text)
#

class Song < ApplicationRecord
  include GraphConcern
  include DateConcern
  include ChartConcern
  include TimeAnalyticsConcern

  has_many :artists_songs
  has_many :artists, through: :artists_songs
  has_many :air_plays
  has_many :radio_station_songs, dependent: :destroy
  has_many :radio_stations, through: :radio_station_songs
  has_many :chart_positions, as: :positianable

  before_create :set_search_text
  after_commit :update_search_text, on: [:update], if: :saved_change_to_title?
  after_commit :update_youtube_from_wikipedia, on: %i[create update], if: :should_update_youtube?
  after_commit :enrich_with_deezer, on: %i[create update], if: :should_enrich_with_deezer?
  after_commit :enrich_with_itunes, on: %i[create update], if: :should_enrich_with_itunes?

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
    start_time, end_time = time_range_from_params(params, default_period: 'week')

    Song.joins(:air_plays)
        .played_between(start_time, end_time)
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
                 songs.id_on_deezer,
                 songs.deezer_song_url,
                 songs.deezer_artwork_url,
                 songs.deezer_preview_url,
                 songs.id_on_itunes,
                 songs.itunes_song_url,
                 songs.itunes_artwork_url,
                 songs.itunes_preview_url,
                 songs.release_date,
                 songs.release_date_precision,
                 COUNT(air_plays.id) AS counter,
                 ROW_NUMBER() OVER (ORDER BY COUNT(air_plays.id) DESC NULLS LAST) AS position")
        .group('songs.id, songs.title')
        .order('COUNTER DESC NULLS LAST')
  end

  def self.most_played_group_by(column, params)
    most_played(params).group_by(&column)
  end

  def self.search(search_term)
    where('search_text ILIKE ?', "%#{search_term}%")
  end

  def cleanup
    destroy if air_plays.blank?
    artists.each(&:cleanup)
  end

  def update_artists(song_artists)
    return if song_artists.blank?

    self.artists = Array.wrap(song_artists)
    update_search_text
  end

  def played
    air_plays.size
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
    update_air_plays_obsolete_songs(songs, most_played_song)
    cleanup_radio_station_songs(songs, most_played_song)
    remove_absolute_songs(songs)
  end

  def find_same_songs
    # Use map instead of pluck when artists are already loaded to avoid extra query
    artist_ids = artists.loaded? ? artists.map(&:id) : artists.pluck(:id)
    Song.joins(:artists).where(artists: { id: artist_ids }).where('lower(title) = ?', title&.downcase)
  end

  def spotify_track
    return if id_on_spotify.blank?

    @spotify_track ||= Spotify::TrackFinder::FindById.new(id_on_spotify: id_on_spotify).execute
  end

  def update_youtube_from_wikipedia
    return if id_on_youtube.present?

    artist_name = artists.first&.name
    song_finder = Wikipedia::SongFinder.new

    # Try by Spotify ID first (most reliable)
    if id_on_spotify.present?
      youtube_id = song_finder.get_youtube_video_id_by_spotify_id(id_on_spotify)
      return update(id_on_youtube: youtube_id) if youtube_id.present?
    end

    # Try by ISRC
    if isrc.present?
      youtube_id = song_finder.get_youtube_video_id_by_isrc(isrc)
      return update(id_on_youtube: youtube_id) if youtube_id.present?
    end

    # Fallback to title + artist search
    youtube_id = song_finder.get_youtube_video_id(title, artist_name)
    update(id_on_youtube: youtube_id) if youtube_id.present?
  end

  private

  def update_air_plays_obsolete_songs(songs, most_played_song)
    AirPlay.where(song: songs).update_all(song_id: most_played_song.id)
  end

  def remove_absolute_songs(songs)
    songs.each(&:cleanup)
  end

  def cleanup_radio_station_songs(songs, most_played_song)
    RadioStation.unscoped.find_each do |radio_station|
      air_plays = AirPlay.where(song: [songs, most_played_song], radio_station:)
      next if air_plays.blank?

      RadioStationSong.where(song: songs, radio_station:).delete_all

      rss = RadioStationSong.find_or_initialize_by(song: most_played_song, radio_station:)
      rss.first_broadcasted_at = air_plays.minimum(:broadcasted_at)
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

  def should_update_youtube?
    id_on_youtube.blank? && (id_on_spotify.present? || isrc.present? || title.present?)
  end

  def should_enrich_with_deezer?
    id_on_deezer.blank? && (isrc.present? || title.present?)
  end

  def should_enrich_with_itunes?
    id_on_itunes.blank? && title.present?
  end

  def enrich_with_deezer
    Deezer::SongEnricher.new(self).enrich
  end

  def enrich_with_itunes
    Itunes::SongEnricher.new(self).enrich
  end

  # Enrich song with Deezer and iTunes data if missing
  def enrich_with_external_services
    enrich_with_deezer if should_enrich_with_deezer?
    enrich_with_itunes if should_enrich_with_itunes?
  end
end
