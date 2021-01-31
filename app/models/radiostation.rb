class Radiostation < ActiveRecord::Base
  has_many :generalplaylists
  has_many :songs, through: :generalplaylists
  has_many :artists, through: :songs

  validates :url, :processor, presence: true

  include Importable

  def status
    last_created.created_at > 3.hour.ago ? 'ok' : 'warning'
  end

  def mail_data
    {
      id: id,
      name: name,
      status: status,
      last_created_at: last_created.created_at,
      track_info: "#{last_created.song.artists.map(&:name).join(' & ')} - #{last_created.song.title}",
      total_created: todays_added_items.count
    }
  end

  def last_created
    Generalplaylist.where(radiostation: self).order(created_at: :desc).first
  end

  def todays_added_items
    Generalplaylist.where(radiostation: self, created_at: 1.day.ago..Time.zone.now)
  end

  def import_song
    radio_station = self
    artist_name, title, broadcast_timestamp = send(radio_station.processor.to_sym)

    return false if artist_name.blank?
    return false if illegal_word_in_title(title)

    artists, song = process_track_data(artist_name, title)
    create_generalplaylist(broadcast_timestamp, artists, song, radio_station)
  end
end
