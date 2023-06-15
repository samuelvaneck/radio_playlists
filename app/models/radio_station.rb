# frozen_string_literal: true

# == Schema Information
#
# Table name: radio_stations
#
#  id         :bigint           not null, primary key
#  name       :string
#  genre      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  url        :text
#  processor  :string
#  stream_url :string
#

class RadioStation < ActiveRecord::Base
  has_many :playlists
  has_many :songs, through: :playlists
  has_many :artists, through: :songs
  has_many :song_recognizer_logs

  validates :url, :processor, presence: true

  include TrackDataProcessor

  def status
    return 'warning' if zero_playlist_items

    last_created.created_at > 3.hour.ago ? 'ok' : 'warning'
  end

  def status_data
    return {} if zero_playlist_items

    {
      id:,
      name:,
      status:,
      last_created_at: last_created&.created_at,
      track_info: "#{last_created&.song&.artists&.map(&:name)&.join(' & ')} - #{last_created&.song&.title}",
      total_created: todays_added_items&.count
    }
  end

  def last_created
    Playlist.where(radio_station: self).order(created_at: :desc).first
  end

  def todays_added_items
    Playlist.where(radio_station: self, created_at: 1.day.ago..Time.zone.now)
  end

  def import_song
    importing_song = recognize_song || scrape_song
    return false if importing_song.blank?
    return false if illegal_word_in_title(importing_song.title) || importing_song.artist_name.blank?
    return false unless song_recognized_twice?(title: importing_song.title, artist: importing_song.artist_name)

    artists, song = process_track_data(importing_song.artist_name, importing_song.title, importing_song.spotify_url, importing_song.isrc_code)
    return false if artists.nil? || song.nil?

    scraper_import = importing_song.is_a?(TrackScraper)
    create_playlist(importing_song.broadcast_timestamp, artists, song, scraper_import)
  rescue StandardError => e
    Sentry.capture_exception(e)
    Rails.logger.error "Error while importing song from #{name}: #{e.message}"
    nil
  end

  def zero_playlist_items
    Playlist.where(radio_station: self).count.zero?
  end

  def enqueue_recognize_song
    RadioStationRecognizeSongJob.perform_later(id)
  end

  def recognize_song
    recognizer = SongRecognizer.new(self)
    return nil unless recognizer.recognized?

    recognizer
  end

  def scrape_song
    scrapper = "TrackScraper::#{processor.camelcase}".constantize.new(self)
    return nil unless scrapper.last_played_song

    scrapper
  end

  def audio_file_name
    name.downcase.gsub(/\W/, '')
  end

  def audio_file_path
    sanitize_file_name = ActiveStorage::Filename.new("#{audio_file_name}.mp3").sanitized
    Rails.root.join("tmp/audio/#{sanitize_file_name}")
  end

  def last_played_song
    playlists.order(created_at: :desc).first&.song
  end

  def songs_played_last_hour
    playlists.where(created_at: 1.hour.ago..Time.zone.now).map(&:song)
  end

  private

  def create_playlist(broadcast_timestamp, artists, song, scraper_import)
    if scraper_import
      import_from_scraper(broadcast_timestamp, artists, song)
    elsif last_played_song != song && !any_song_matches?(song)
      add_song(broadcast_timestamp, artists, song, false)
    else
      Rails.logger.info "#{song.title} from #{Array.wrap(artists).map(&:name).join(', ')} last song on #{name}"
    end
  end

  def add_song(broadcast_timestamp, artists, song, scraper_import)
    Playlist.add_playlist(self, song, broadcast_timestamp, scraper_import)
    song.update_artists(artists)
    artists_names = Array.wrap(artists).map(&:name).join(', ')
    artists_ids = Array.wrap(artists).map(&:id).join(' ')

    Rails.logger.info "Saved #{song.title} (#{song.id}) from #{artists_names} (#{artists_ids}) on #{name}!"
  end

  def import_from_scraper(broadcast_timestamp, artists, song)
    last_added_scraper_song = playlists.scraper_imported&.order(created_at: :desc)&.first&.song
    if any_song_matches?(song) || last_added_scraper_song == song
      Rails.logger.info "#{song.title} from #{Array.wrap(artists).map(&:name).join(', ')} last song on #{name}"
    else
      add_song(broadcast_timestamp, artists, song, true)
    end
  end

  ### check if any song played last hour matches the song we are importing
  def any_song_matches?(importing_song)
    song_matches(importing_song).map { |n| n > 80 }.any?
  end

  def song_matches(importing_song)
    songs_played_last_hour.map do |played_song|
      song_match(played_song, importing_song)
    end
  end

  def song_match(played_song, importing_song)
    played_song_fullname = "#{played_song.artists.map(&:name).join(' ')} #{played_song.title}".downcase
    importing_song_fullname = "#{importing_song.artists.map(&:name).join(' ')} #{importing_song.title}".downcase
    (JaroWinkler.distance(played_song_fullname, importing_song_fullname) * 100).to_i
  end

  def song_recognized_twice?(title:, artist:)
    cache_key = "#{id}-#{artist.downcase.gsub(/\W/, '')}-#{title.downcase.gsub(/\W/, '')}"
    if Rails.cache.exist?(cache_key)
      Rails.cache.delete_matched("#{id}*")
      true
    else
      # first delete any existing keys from radio station before write
      Rails.cache.delete_matched("#{id}*")
      Rails.cache.write(cache_key, Time.zone.now.to_i)
      false
    end
  end
end
