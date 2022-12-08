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
    scrapper = TrackScrapper.new(self)
    return false unless scrapper.latest_track
    return false if illegal_word_in_title(scrapper.title) || scrapper.artist_name.blank?

    artists, song = process_track_data(scrapper.artist_name, scrapper.title, scrapper.spotify_url)
    return false if artists.nil? || song.nil?

    create_playlist(scrapper.broadcast_timestamp, artists, song)
  rescue StandardError => e
    Sentry.capture_exception(e)
    Rails.logger.error "Error while importing song from #{name}: #{e.message}"
    nil
  end

  def zero_playlist_items
    Playlist.where(radio_station: self).count.zero?
  end

  private

  def create_playlist(broadcast_timestamp, artists, song)
    if Playlist.last_played_song(self, song, broadcast_timestamp).blank?
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
