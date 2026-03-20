# frozen_string_literal: true

class BarChartRace
  TOP_N = 10

  include DateConcern

  def initialize(radio_station:, params:)
    @radio_station = radio_station
    @params = params
    @start_time, @end_time = self.class.time_range_from_params(params, default_period: 'week')
  end

  def frames
    daily_counts = fetch_daily_counts
    songs_by_id = fetch_songs(daily_counts)
    build_frames(daily_counts, songs_by_id)
  end

  def meta
    {
      period: @params[:period],
      start_time: @start_time.iso8601,
      end_time: @end_time.iso8601
    }
  end

  private

  def fetch_daily_counts
    counts = AirPlay.confirmed
               .where(radio_station: @radio_station)
               .where(broadcasted_at: @start_time..@end_time)
               .group(:song_id, Arel.sql('DATE(broadcasted_at)'))
               .count

    counts.each_with_object({}) do |((song_id, date), count), hash|
      hash[date.to_s] ||= {}
      hash[date.to_s][song_id] = count
    end
  end

  def fetch_songs(daily_counts)
    song_ids = daily_counts.values.flat_map(&:keys).uniq
    Song.where(id: song_ids).preload(:artists).index_by(&:id)
  end

  def build_frames(daily_counts, songs_by_id)
    dates = (@start_time.to_date..@end_time.to_date).map(&:to_s)
    cumulative = Hash.new(0)

    dates.filter_map do |date|
      day_counts = daily_counts[date]
      next if day_counts.blank? && cumulative.empty?

      day_counts&.each { |song_id, count| cumulative[song_id] += count }

      build_frame(date, cumulative, songs_by_id)
    end
  end

  def build_frame(date, cumulative, songs_by_id)
    top_songs = cumulative.sort_by { |_, count| -count }.first(TOP_N)
    return if top_songs.empty?

    {
      date: date,
      entries: top_songs.filter_map.with_index do |(song_id, count), index|
        song = songs_by_id[song_id]
        next unless song

        { position: index + 1, count: count, song: serialize_song(song) }
      end
    }
  end

  def serialize_song(song)
    {
      id: song.id,
      title: song.title,
      spotify_artwork_url: song.spotify_artwork_url,
      artists: song.artists.map { |a| { id: a.id, name: a.name } }
    }
  end
end
