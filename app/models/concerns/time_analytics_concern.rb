# frozen_string_literal: true

module TimeAnalyticsConcern
  extend ActiveSupport::Concern

  included do
    include LifecycleConcern
  end

  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  # Peak play times - which hours and days a song is played most
  def peak_play_hours(radio_station_ids: nil)
    filtered_air_plays(radio_station_ids)
      .group('EXTRACT(HOUR FROM broadcasted_at)::integer')
      .order(Arel.sql('COUNT(*) DESC'))
      .count
  end

  def peak_play_days(radio_station_ids: nil)
    filtered_air_plays(radio_station_ids)
      .group('EXTRACT(DOW FROM broadcasted_at)::integer')
      .order(Arel.sql('COUNT(*) DESC'))
      .count
  end

  def peak_play_times_summary(radio_station_ids: nil)
    hours = peak_play_hours(radio_station_ids: radio_station_ids).compact
    days = peak_play_days(radio_station_ids: radio_station_ids).compact

    {
      peak_hour: hours.first&.first,
      peak_day: days.first&.first,
      peak_day_name: days.first&.first ? DAY_NAMES[days.first.first] : nil,
      hourly_distribution: hours,
      daily_distribution: days.transform_keys { |dow| DAY_NAMES[dow] }
    }
  end

  # Play frequency trend - is the song trending up or down
  def play_frequency_trend(weeks: 4, radio_station_ids: nil)
    return nil if air_plays.count < 2

    weekly_counts = fetch_weekly_counts(weeks, radio_station_ids)
    return nil if weekly_counts.size < 2

    build_trend_result(weekly_counts)
  end

  def trending_up?(weeks: 4, radio_station_ids: nil)
    trend = play_frequency_trend(weeks: weeks, radio_station_ids: radio_station_ids)
    trend && trend[:trend] == :rising
  end

  def trending_down?(weeks: 4, radio_station_ids: nil)
    trend = play_frequency_trend(weeks: weeks, radio_station_ids: radio_station_ids)
    trend && trend[:trend] == :falling
  end

  private

  def filtered_air_plays(radio_station_ids)
    query = air_plays
    query = query.where(radio_station_id: radio_station_ids) if radio_station_ids.present?
    query
  end

  def fetch_weekly_counts(weeks, radio_station_ids)
    start_date = weeks.weeks.ago.beginning_of_week
    end_date = Time.current.beginning_of_week

    actual_counts = filtered_air_plays(radio_station_ids)
                    .where('broadcasted_at >= ?', start_date)
                    .group("DATE_TRUNC('week', broadcasted_at)")
                    .count

    all_weeks = {}
    current_week = start_date
    while current_week <= end_date
      matching_key = actual_counts.keys.find { |k| k.to_date == current_week.to_date }
      all_weeks[current_week] = matching_key ? actual_counts[matching_key] : 0
      current_week += 1.week
    end

    all_weeks
  end

  def build_trend_result(weekly_counts)
    first_avg, second_avg = calculate_period_averages(weekly_counts.values)
    trend_percentage = calculate_trend_percentage(first_avg, second_avg)

    {
      trend: trend_direction(trend_percentage),
      trend_percentage: trend_percentage,
      weekly_counts: weekly_counts.transform_keys { |date| date.strftime('%Y-%m-%d') },
      first_period_avg: first_avg.round(1),
      second_period_avg: second_avg.round(1)
    }
  end

  def calculate_period_averages(counts)
    first_half = counts[0...(counts.size / 2)]
    second_half = counts[(counts.size / 2)..]

    first_avg = first_half.sum.to_f / first_half.size
    second_avg = second_half.sum.to_f / second_half.size

    [first_avg, second_avg]
  end

  def calculate_trend_percentage(first_avg, second_avg)
    return 0 unless first_avg.positive?

    ((second_avg - first_avg) / first_avg * 100).round(1)
  end

  def trend_direction(percentage)
    return :rising if percentage > 10
    return :falling if percentage < -10

    :stable
  end
end
