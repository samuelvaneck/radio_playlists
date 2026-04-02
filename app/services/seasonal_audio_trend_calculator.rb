# frozen_string_literal: true

# Calculates seasonal audio feature trends by aggregating MusicProfile data
# across airplays grouped by month.
#
# Research shows music listening patterns are seasonal:
# - Valence (positivity) is lowest in January, peaks in June/July
# - Summer hits cluster around 118 BPM with high energy and danceability
# - Fall/winter shows higher danceability while spring/summer shows higher valence
#
# Usage:
#   calculator = SeasonalAudioTrendCalculator.new(
#     radio_station_ids: [1, 2],
#     start_time: 1.year.ago,
#     end_time: Time.current
#   )
#   result = calculator.calculate
#
# References:
#   - Spotify seasonal mood analysis
#   - Park et al. (2019): "Global music streaming data reveal diurnal and seasonal patterns"
class SeasonalAudioTrendCalculator
  FEATURES = %i[valence energy danceability tempo].freeze

  def initialize(radio_station_ids: nil, start_time: nil, end_time: nil)
    @radio_station_ids = radio_station_ids
    @start_time = start_time || 1.year.ago
    @end_time = end_time || Time.current
  end

  def calculate
    return nil if monthly_data.empty?

    {
      period: { start_time: @start_time.iso8601, end_time: @end_time.iso8601 },
      features: FEATURES,
      series: build_series,
      summary: build_summary
    }
  end

  private

  def build_series
    @build_series ||= monthly_data.map { |row| serialize_row(row) }
  end

  def serialize_row(row)
    station_id = row['radio_station_id']&.to_i
    {
      month: row['month'],
      radio_station_id: station_id,
      radio_station_name: station_names[station_id],
      sample_size: row['sample_size'].to_i
    }.merge(feature_values(row))
  end

  def feature_values(row)
    {
      valence: row['avg_valence']&.to_f&.round(3),
      energy: row['avg_energy']&.to_f&.round(3),
      danceability: row['avg_danceability']&.to_f&.round(3),
      tempo: row['avg_tempo']&.to_f&.round(1)
    }
  end

  def build_summary
    return {} if build_series.empty?

    FEATURES.to_h { |feature| [:"peak_#{feature}_month", peak_month_for(feature)] }
  end

  def peak_month_for(feature)
    grouped = build_series.group_by { |row| row[:month]&.slice(5, 2) }
    monthly_avgs = grouped.transform_values { |rows| average_feature(rows, feature) }.compact
    monthly_avgs.max_by { |_, avg| avg || 0 }&.first
  end

  def average_feature(rows, feature)
    values = rows.filter_map { |r| r[feature] }
    return nil if values.empty?

    (values.sum / values.size).round(3)
  end

  def monthly_data
    @monthly_data ||= begin
      scope = MusicProfile
                .joins(song: :air_plays)
                .where(air_plays: { broadcasted_at: @start_time..@end_time, status: :confirmed })

      scope = scope.where(air_plays: { radio_station_id: @radio_station_ids }) if @radio_station_ids.present?

      scope
        .select(
          "TO_CHAR(DATE_TRUNC('month', air_plays.broadcasted_at), 'YYYY-MM') AS month",
          'air_plays.radio_station_id AS radio_station_id',
          'AVG(music_profiles.valence) AS avg_valence',
          'AVG(music_profiles.energy) AS avg_energy',
          'AVG(music_profiles.danceability) AS avg_danceability',
          'AVG(music_profiles.tempo) AS avg_tempo',
          'COUNT(DISTINCT songs.id) AS sample_size'
        )
        .group(Arel.sql("DATE_TRUNC('month', air_plays.broadcasted_at), air_plays.radio_station_id"))
        .order(Arel.sql("DATE_TRUNC('month', air_plays.broadcasted_at)"))
        .to_a
    end
  end

  def station_names
    @station_names ||= RadioStation.where(id: @radio_station_ids || monthly_station_ids).pluck(:id, :name).to_h
  end

  def monthly_station_ids
    monthly_data.map { |row| row['radio_station_id']&.to_i }.compact.uniq
  end
end
