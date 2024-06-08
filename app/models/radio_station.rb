# frozen_string_literal: true

# == Schema Information
#
# Table name: radio_stations
#
#  id                  :bigint           not null, primary key
#  name                :string
#  genre               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  url                 :text
#  processor           :string
#  stream_url          :string
#  last_played_song_id :integer
#  slug                :string
#  country_code        :string
#

class RadioStation < ActiveRecord::Base
  has_many :playlists
  has_many :songs, through: :playlists
  has_many :artists, through: :songs
  has_many :song_recognizer_logs

  validates :name, presence: true
  validates :name, uniqueness: true

  def status_data
    return {} if zero_playlist_items

    {
      id:,
      name:,
      last_played_song_at: playlists.order(created_at: :desc).first&.broadcasted_at,
      track_info: "#{last_played_song&.artists&.map(&:name)&.join(' & ')} - #{last_played_song&.title}",
      total_created: today_added_items&.count
    }
  end

  def today_added_items
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

  def logo_path
    "radio_station_logos/#{audio_file_name}.png"
  end

  def last_played_song
    Song.find_by(id: last_played_song_id)
  end

  def self.last_played_songs
    all.map do |radio_station|
      {
        id: radio_station.id,
        name: radio_station.name,
        slug: radio_station.slug,
        stream_url: radio_station.stream_url,
        country_code: radio_station.country_code,
        last_played_song: SongSerializer.new(radio_station.last_played_song).serializable_hash
      }
    end
  end

  def songs_played_last_hour
    playlists.where(created_at: 1.hour.ago..Time.zone.now).map(&:song)
  end

  def update_last_played_song_id(song_id)
    update(last_played_song_id: song_id)
  end
end
