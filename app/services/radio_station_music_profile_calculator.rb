# frozen_string_literal: true

class RadioStationMusicProfileCalculator
  DAY_PARTS = %w[night breakfast morning lunch afternoon dinner evening].freeze

  DAY_PART_HOURS = {
    'night' => (0..5),
    'breakfast' => (6..9),
    'morning' => (10..11),
    'lunch' => (12..12),
    'afternoon' => (13..15),
    'dinner' => (16..19),
    'evening' => (20..23)
  }.freeze

  AUDIO_FEATURES = MusicProfile::AUDIO_FEATURES
  HIGH_VALUE_THRESHOLDS = MusicProfile::HIGH_VALUE_THRESHOLDS

  def initialize(radio_station:, day_part: nil, start_time: nil, end_time: nil)
    @radio_station = radio_station
    @day_part = day_part
    @start_time = start_time || 1.month.ago
    @end_time = end_time || Time.current
  end

  def calculate
    if @day_part.present?
      [calculate_for_day_part(@day_part)].compact
    else
      DAY_PARTS.filter_map { |dp| calculate_for_day_part(dp) }
    end
  end

  def calculate_for_day_part(day_part)
    profiles = music_profiles_for_day_part(day_part)
    return nil if profiles.empty?

    build_aggregated_profile(day_part, profiles)
  end

  private

  def music_profiles_for_day_part(day_part)
    hours = DAY_PART_HOURS[day_part].to_a
    timezone = Time.zone.tzinfo.name

    MusicProfile
      .joins(song: :air_plays)
      .where(air_plays: {
               radio_station_id: @radio_station.id,
               broadcasted_at: @start_time..@end_time
             })
      .where("EXTRACT(HOUR FROM air_plays.broadcasted_at AT TIME ZONE 'UTC' AT TIME ZONE ?) IN (?)", timezone, hours)
      .distinct
  end

  def build_aggregated_profile(day_part, profiles)
    counter = profiles.count

    result = {
      day_part:,
      counter:,
      tempo: calculate_average(profiles, :tempo)
    }

    AUDIO_FEATURES.each do |feature|
      result[:"#{feature}_average"] = calculate_average(profiles, feature)
      result[:"high_#{feature}_percentage"] = calculate_high_percentage(profiles, feature)
    end

    result
  end

  def calculate_average(profiles, feature)
    values = profiles.pluck(feature).compact
    return 0.0 if values.empty?

    (values.sum / values.size).round(3)
  end

  def calculate_high_percentage(profiles, feature)
    threshold = HIGH_VALUE_THRESHOLDS[feature.to_sym]
    return 0.0 if threshold.nil?

    values = profiles.pluck(feature).compact
    return 0.0 if values.empty?

    high_count = values.count { |v| v > threshold }
    (high_count.to_f / values.size).round(4)
  end
end
