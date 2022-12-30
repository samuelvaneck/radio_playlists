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
    return false if illegal_word_in_title(importing_song.title) || importing_song.artist_name.blank?

    artists, song = process_track_data(importing_song.artist_name, importing_song.title, importing_song.spotify_url)
    return false if artists.nil? || song.nil?

    create_playlist(importing_song.broadcast_timestamp, artists, song)
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
    scrapper = TrackScrapper.new(self)
    return nil unless scrapper.latest_track

    scrapper
  end

  def audio_file_name
    name.downcase.tr(' ', '_')
  end

  def audio_file_path
    Rails.root.join("tmp/audio/#{audio_file_name}.mp3")
  end

  def last_played_song
    Playlist.where(radio_station: self).order(created_at: :desc).first&.song
  end

  private

  def create_playlist(broadcast_timestamp, artists, song)
    if last_played_song != song
      add_song(broadcast_timestamp, artists, song)
    else
      Rails.logger.info "#{song.title} from #{Array.wrap(artists).map(&:name).join(', ')} last song on #{name}"
    end
  end

  def add_song(broadcast_timestamp, artists, song)
    Playlist.add_playlist(self, song, broadcast_timestamp)
    song.update_artists(artists)
    artists_names = Array.wrap(artists).map(&:name).join(', ')
    artists_ids = Array.wrap(artists).map(&:id).join(' ')

    Rails.logger.info "Saved #{song.title} (#{song.id}) from #{artists_names} (#{artists_ids}) on #{name}!"
  end
end
