# frozen_string_literal: true

# == Schema Information
#
# Table name: radio_stations
#
#  id                      :bigint           not null, primary key
#  name                    :string
#  genre                   :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  url                     :text
#  processor               :string
#  stream_url              :string
#  slug                    :string
#  country_code            :string
#  last_added_playlist_ids :jsonb
#

class RadioStation < ActiveRecord::Base
  has_many :playlists
  has_many :radio_station_songs
  has_many :songs, through: :radio_station_songs
  has_many :artists, through: :songs
  has_many :radio_station_classifiers, dependent: :destroy
  has_many :tags, dependent: :destroy, as: :taggable

  default_scope -> { order(name: :asc) }

  validates :name, presence: true
  validates :name, uniqueness: true

  def self.last_played_songs
    all.map do |radio_station|
      {
        id: radio_station.id,
        name: radio_station.name,
        slug: radio_station.slug,
        stream_url: radio_station.stream_url,
        country_code: radio_station.country_code,
        last_played_song: PlaylistSerializer.new(radio_station.last_added_playlists).serializable_hash
      }
    end
  end

  def self.new_songs_played_for_period(params)
    time_value = params[:start_time]
    period_start = time_value == 'all' ? nil : 1.send(time_value.to_sym).ago
    period_end = Time.current

    RadioStationSong.includes(:radio_station, song: :artists)
                    .played_between(period_start, period_end)
                    .played_on(params[:radio_station_ids])
                    .sort do |a, b|
                      a_sorted = a.song.playlists.where(radio_station_id: a.radio_station_id).count
                      b_sorted = b.song.playlists.where(radio_station_id: b.radio_station_id).count
                      b_sorted <=> a_sorted
                    end
  end

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
    last_added_playlists.first&.song
  end

  def last_added_playlists
    playlists.where(id: last_added_playlist_ids).order(created_at: :desc)
  end

  def songs_played_last_hour
    playlists.where(created_at: 1.hour.ago..Time.zone.now).map(&:song)
  end

  def update_last_added_playlist_ids(playlist_id)
    current_last_added_playlist_ids = Array.wrap(last_added_playlist_ids)
    current_last_added_playlist_ids << playlist_id
    current_last_added_playlist_ids.shift if current_last_added_playlist_ids.count > 12

    update(last_added_playlist_ids: current_last_added_playlist_ids)
  end

  def data
    {
      id: id,
      name: name,
      genre: genre,
      url: url,
      processor: processor,
      stream_url: stream_url,
      country_code: country_code,
      last_added_playlist_ids: last_added_playlist_ids,
      last_played_song: PlaylistSerializer.new(last_added_playlists).serializable_hash
    }
  end
end
