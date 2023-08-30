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

  def stack_prof_import_song
    StackProf.run(mode: :cpu, out: 'tmp/stackprof-cpu-import-song.dump', raw: true) do
      import_song
    end
  end

  def import_song
    SongImporter.new(radio_station: self).import
  end

  def zero_playlist_items
    Playlist.where(radio_station: self).count.zero?
  end

  def enqueue_recognize_song
    RadioStationRecognizeSongJob.perform_later(id)
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
end
