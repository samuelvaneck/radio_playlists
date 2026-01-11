# frozen_string_literal: true

class RadioStationMusicProfileCalculator
  HOURS = (0..23).to_a.freeze

  AUDIO_FEATURES = MusicProfile::AUDIO_FEATURES
  HIGH_VALUE_THRESHOLDS = MusicProfile::HIGH_VALUE_THRESHOLDS

  def initialize(radio_station:, hour: nil, start_time: nil, end_time: nil)
    @radio_station = radio_station
    @hour = hour
    @start_time = start_time || 24.hours.ago
    @end_time = end_time || Time.current
  end

  def calculate
    if @hour.present?
      [calculate_for_hour(@hour)].compact
    else
      HOURS.filter_map { |h| calculate_for_hour(h) }
    end
  end

  def calculate_for_hour(hour)
    profiles = music_profiles_for_hour(hour)
    return nil if profiles.empty?

    build_aggregated_profile(hour, profiles)
  end

  private

  def music_profiles_for_hour(hour)
    timezone = Time.zone.tzinfo.name

    MusicProfile
      .joins(song: :air_plays)
      .where(air_plays: {
               radio_station_id: @radio_station.id,
               broadcasted_at: @start_time..@end_time
             })
      .where("EXTRACT(HOUR FROM air_plays.broadcasted_at AT TIME ZONE 'UTC' AT TIME ZONE ?) = ?", timezone, hour)
      .distinct
  end

  def build_aggregated_profile(hour, profiles)
    all_features = [:tempo] + AUDIO_FEATURES.map(&:to_sym)
    data = profiles.pluck(*all_features)

    return nil if data.empty?

    result = {
      hour:,
      counter: data.size,
      tempo: calculate_average_from_array(data, 0)
    }

    AUDIO_FEATURES.each_with_index do |feature, index|
      column_index = index + 1
      result[:"#{feature}_average"] = calculate_average_from_array(data, column_index)
      result[:"high_#{feature}_percentage"] = calculate_high_percentage_from_array(data, column_index, feature)
    end

    result
  end

  def calculate_average_from_array(data, column_index)
    values = data.filter_map { |row| row[column_index] }
    return 0.0 if values.empty?

    (values.sum / values.size).round(3)
  end

  def calculate_high_percentage_from_array(data, column_index, feature)
    threshold = HIGH_VALUE_THRESHOLDS[feature.to_sym]
    return 0.0 if threshold.nil?

    values = data.filter_map { |row| row[column_index] }
    return 0.0 if values.empty?

    high_count = values.count { |v| v > threshold }
    (high_count.to_f / values.size).round(4)
  end
end
