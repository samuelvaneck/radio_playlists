# frozen_string_literal: true

module BarChartRace
  class DayChart
    include DateConcern

    def initialize(radio_station:, params:)
      @radio_station = radio_station
      @params = params
      @start_time, @end_time = self.class.time_range_from_params(params, default_period: 'day')
    end

    def frames
      song_counts = fetch_song_counts
      return [] if song_counts.empty?

      songs_by_id = fetch_songs(song_counts)
      top_songs = song_counts.sort_by { |_, count| -count }.first(TOP_N)

      [build_frame(top_songs, songs_by_id)]
    end

    def meta
      {
        type: 'day_chart',
        period: @params[:period],
        start_time: @start_time.iso8601,
        end_time: @end_time.iso8601
      }
    end

    private

    def fetch_song_counts
      AirPlay.confirmed
        .where(radio_station: @radio_station)
        .where(broadcasted_at: @start_time..@end_time)
        .group(:song_id)
        .count
    end

    def fetch_songs(song_counts)
      Song.where(id: song_counts.keys).preload(:artists).index_by(&:id)
    end

    def build_frame(top_songs, songs_by_id)
      {
        date: @end_time.to_date.to_s,
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
end
