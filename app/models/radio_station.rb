# frozen_string_literal: true

# == Schema Information
#
# Table name: radio_stations
#
#  id                      :bigint           not null, primary key
#  avg_song_gap_per_hour   :jsonb
#  country_code            :string
#  direct_stream_url       :string
#  genre                   :string
#  import_interval         :integer
#  last_added_air_play_ids :jsonb
#  name                    :string
#  processor               :string
#  slug                    :string
#  url                     :text
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

class RadioStation < ActiveRecord::Base
  VALID_PROCESSORS = %w[
    npo_api_processor
    qmusic_api_processor
    media_huis_api_processor
    talpa_api_processor
    slam_api_processor
    kink_api_processor
    gnr_api_processor
    arrow_api_processor
    yoursafe_video_processor
    mytuner_api_processor
    simone_api_processor
  ].freeze

  include DateConcern

  has_many :air_plays
  has_many :radio_station_songs
  has_many :songs, through: :radio_station_songs
  has_many :artists, through: :songs
  has_many :song_import_logs, dependent: :destroy
  has_many :tags, dependent: :destroy, as: :taggable

  validates :name, presence: true
  validates :name, uniqueness: true, if: :will_save_change_to_name?
  validates :processor, inclusion: { in: VALID_PROCESSORS }, allow_blank: true
  validates :direct_stream_url, format: { with: %r{\Ahttps://}i, message: 'must start with https://' }, allow_blank: true

  scope :recognizer_only, -> { where(processor: [nil, '']) }
  scope :with_api_processor, -> { where.not(processor: [nil, '']) }

  default_scope -> { order(name: :asc) }

  def self.last_played_songs
    all.map do |radio_station|
      last_air_play = radio_station.last_added_air_plays.includes(:song).first
      {
        id: radio_station.id,
        name: radio_station.name,
        slug: radio_station.slug,
        country_code: radio_station.country_code,
        is_currently_playing: currently_playing?(last_air_play),
        last_played_song: AirPlaySerializer.new(
          radio_station.last_added_air_plays.limit(3),
          fields: { air_play: %i[id broadcasted_at created_at status song artists] }
        ).serializable_hash
      }
    end
  end

  def self.currently_playing?(air_play)
    return false if air_play&.broadcasted_at.blank?

    duration_ms = air_play.song&.duration_ms || 300_000
    end_time = air_play.broadcasted_at + (duration_ms / 1000).seconds
    end_time > Time.current
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

  def self.release_date_graph(params)
    start_time, end_time = time_range_from_params(params, default_period: 'year')
    radio_station_ids = Array.wrap(params[:radio_station_ids]).map(&:to_i)

    grouped = release_date_counts(start_time, end_time, radio_station_ids)
    build_release_date_series(grouped, radio_station_ids)
  end

  def self.release_date_counts(start_time, end_time, radio_station_ids)
    counts = AirPlay.joins(:song)
               .where(broadcasted_at: start_time..end_time)
               .where.not(songs: { release_date: nil })
    counts = counts.where(radio_station_id: radio_station_ids) if radio_station_ids.present?

    counts.group(:radio_station_id, Arel.sql('EXTRACT(YEAR FROM songs.release_date)::integer'))
      .count
  end

  def self.build_release_date_series(grouped, radio_station_ids)
    stations = RadioStation.unscoped.pluck(:id, :name).to_h
    filtered_stations = filter_stations(stations, radio_station_ids)

    data = grouped.keys.map(&:last).uniq.sort.map do |year|
      row = { year: year }
      filtered_stations.each { |station_id, name| row[name] = grouped[[station_id, year]] || 0 }
      row
    end

    data << { columns: filtered_stations.values }
  end

  def self.filter_stations(stations, radio_station_ids)
    return stations if radio_station_ids.blank?

    stations.select { |id, _| radio_station_ids.include?(id) }
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

  def sound_profile(start_time: nil, end_time: nil)
    SoundProfileGenerator.new(radio_station: self, start_time: start_time, end_time: end_time).generate
  end

  def widget_data
    day_range = 1.day.ago..Time.zone.now
    week_range = 1.week.ago..Time.zone.now
    station_ids = [id].to_json

    top_song = Song.most_played(radio_station_ids: station_ids, period: 'week').first
    top_artist = Artist.most_played(radio_station_ids: station_ids, period: 'week').first
    songs_played_count = AirPlay.confirmed.where(radio_station: self, broadcasted_at: day_range).count
    new_songs_count = RadioStationSong.where(radio_station: self, first_broadcasted_at: week_range).count

    {
      top_song: top_song ? SongSerializer.new(top_song).serializable_hash : nil,
      top_artist: top_artist ? ArtistSerializer.new(top_artist).serializable_hash : nil,
      songs_played_count: songs_played_count,
      new_songs_count: new_songs_count
    }
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
    Rails.root.join("tmp/audio/persistent/#{audio_file_name}.mp3")
  end

  def logo_path
    "radio_station_logos/#{audio_file_name}.png"
  end

  def last_played_song
    last_added_air_plays.includes(:song).first&.song
  end

  def last_added_air_plays
    air_plays.where(id: last_added_air_play_ids).order(created_at: :desc)
  end

  def songs_played_last_hour
    Song.joins(:air_plays)
      .where(air_plays: { radio_station_id: id, created_at: 1.hour.ago..Time.zone.now })
      .includes(:artists)
      .distinct
  end

  def update_last_added_air_play_ids(air_play_id)
    current_last_added_air_play_ids = Array.wrap(last_added_air_play_ids)
    current_last_added_air_play_ids << air_play_id
    current_last_added_air_play_ids.shift if current_last_added_air_play_ids.count > 12

    update(last_added_air_play_ids: current_last_added_air_play_ids)
  end

  def calculate_avg_song_gap_per_hour(days: 7)
    averages = gaps_by_hour(days).transform_values { |gaps| (gaps.sum.to_f / gaps.size).round }
    update(avg_song_gap_per_hour: averages)
    averages
  end

  def expected_song_gap(hour: Time.current.utc.hour)
    avg_song_gap_per_hour&.fetch(hour.to_s, nil)
  end

  def data
    {
      id: id,
      name: name,
      genre: genre,
      url: url,
      processor: processor,
      country_code: country_code,
      last_added_air_play_ids: last_added_air_play_ids,
      last_played_song: AirPlaySerializer.new(last_added_air_plays).serializable_hash
    }
  end

  private

  def gaps_by_hour(days)
    broadcasted_at_timestamps(days).each_cons(2)
      .each_with_object(Hash.new { |h, k| h[k] = [] }) do |(prev_time, next_time), result|
        gap_seconds = (next_time - prev_time).to_i
        next if gap_seconds > 900

        result[prev_time.utc.hour] << gap_seconds
      end
  end

  def broadcasted_at_timestamps(days)
    air_plays
      .where(broadcasted_at: days.days.ago..Time.current)
      .order(:broadcasted_at)
      .pluck(:broadcasted_at)
  end
end
