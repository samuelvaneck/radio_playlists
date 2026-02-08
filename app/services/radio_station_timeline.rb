# frozen_string_literal: true

class RadioStationTimeline
  include DateConcern

  def initialize(radio_station:, params:)
    @radio_station = radio_station
    @params = params
    @start_time, @end_time = self.class.time_range_from_params(params, default_period: 'week')
  end

  def songs
    songs = base_songs
    attach_daily_plays(songs)
    songs
  end

  def meta
    {
      period: @params[:period],
      start_time: @start_time.iso8601,
      end_time: @end_time.iso8601
    }
  end

  private

  def base_songs
    Song.most_played(@params.merge(radio_station_ids: [@radio_station.id]))
  end

  def attach_daily_plays(songs)
    song_ids = songs.map(&:id)
    return if song_ids.empty?

    daily_counts = fetch_daily_counts(song_ids)

    songs.each do |song|
      song_daily = daily_counts[song.id] || {}
      song.define_singleton_method(:daily_plays) { song_daily }
    end
  end

  def fetch_daily_counts(song_ids)
    counts = AirPlay.confirmed
               .where(radio_station: @radio_station, song_id: song_ids)
               .where(broadcasted_at: @start_time..@end_time)
               .group(:song_id, Arel.sql('DATE(broadcasted_at)'))
               .count

    counts.each_with_object({}) do |((song_id, date), count), hash|
      hash[song_id] ||= {}
      hash[song_id][date.to_s] = count
    end
  end
end
