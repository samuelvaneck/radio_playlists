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
#  last_added_air_play_ids :jsonb
#

class RadioStation < ActiveRecord::Base
  include DateConcern

  has_many :air_plays
  has_many :radio_station_songs
  has_many :songs, through: :radio_station_songs
  has_many :artists, through: :songs
  has_many :song_import_logs, dependent: :destroy
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
        last_played_song: AirPlaySerializer.new(radio_station.last_added_air_plays).serializable_hash
      }
    end
  end

  def self.new_songs_played_for_period(params)
    start_time, end_time = time_range_from_params(params, default_period: 'day')

    RadioStationSong.includes(:radio_station, song: :artists)
      .played_between(start_time, end_time)
      .played_on(params[:radio_station_ids])
      .joins('INNER JOIN air_plays ON air_plays.song_id = radio_station_songs.song_id
                                                 AND air_plays.radio_station_id = radio_station_songs.radio_station_id')
      .select('radio_station_songs.*, COUNT(air_plays.id) AS air_plays_count')
      .group('radio_station_songs.id')
      .order('air_plays_count DESC')
  end

  def status_data
    return {} if zero_air_play_items

    {
      id:,
      name:,
      last_played_song_at: air_plays.order(created_at: :desc).first&.broadcasted_at,
      track_info: "#{last_played_song&.artists&.map(&:name)&.join(' & ')} - #{last_played_song&.title}",
      total_created: today_added_items&.count
    }
  end

  def today_added_items
    AirPlay.where(radio_station: self, created_at: 1.day.ago..Time.zone.now)
  end

  def stack_prof_import_song
    StackProf.run(mode: :cpu, out: 'tmp/stackprof-cpu-import-song.dump', raw: true)
  end

  def import_song
    SongImporter.new(radio_station: self).import
  end

  def zero_air_play_items
    AirPlay.where(radio_station: self).count.zero?
  end

  def enqueue_recognize_song
    RadioStationRecognizeSongJob.perform_later(id)
  end

  def audio_file_name
    name&.downcase&.gsub(/\W/, '')
  end

  def audio_file_path
    sanitize_file_name = ActiveStorage::Filename.new("#{audio_file_name}.mp3").sanitized
    Rails.root.join("tmp/audio/#{sanitize_file_name}")
  end

  def logo_path
    "radio_station_logos/#{audio_file_name}.png"
  end

  def last_played_song
    last_added_air_plays.confirmed.includes(:song).first&.song
  end

  def last_added_air_plays
    air_plays.where(id: last_added_air_play_ids).order(created_at: :desc)
  end

  def songs_played_last_hour
    Song.joins(:air_plays)
      .where(air_plays: { radio_station_id: id, created_at: 1.hour.ago..Time.zone.now })
      .merge(AirPlay.confirmed)
      .includes(:artists)
      .distinct
  end

  def update_last_added_air_play_ids(air_play_id)
    current_last_added_air_play_ids = Array.wrap(last_added_air_play_ids)
    current_last_added_air_play_ids << air_play_id
    current_last_added_air_play_ids.shift if current_last_added_air_play_ids.count > 12

    update(last_added_air_play_ids: current_last_added_air_play_ids)
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
      last_added_air_play_ids: last_added_air_play_ids,
      last_played_song: AirPlaySerializer.new(last_added_air_plays).serializable_hash
    }
  end
end
