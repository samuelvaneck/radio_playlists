class RadioStation < ActiveRecord::Base
  has_many :playlists
  has_many :songs, through: :playlists
  has_many :artists, through: :songs

  validates :url, :processor, presence: true

  include Importable

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
    radio_station = self
    track = TrackScrapper.new(self).latest_track
    return false if track.blank? || track[:artist_name].blank?
    return false if illegal_word_in_title(track[:title])

    artists, song = process_track_data(track[:artist_name], track[:title])
    return false if artists.nil? || song.nil?

    create_playlist(track[:broadcast_timestamp], artists, song, radio_station)
  rescue StandardError => e
    Sentry.capture_exception(e)
    nil
  end

  def zero_playlist_items
    Playlist.where(radio_station: self).count.zero?
  end
end
