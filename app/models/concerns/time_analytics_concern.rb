# frozen_string_literal: true

module TimeAnalyticsConcern
  extend ActiveSupport::Concern

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
    hours = peak_play_hours(radio_station_ids: radio_station_ids)
    days = peak_play_days(radio_station_ids: radio_station_ids)

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

  # Song lifecycle stats
  def lifecycle_stats(radio_station_ids: nil)
    query = filtered_air_plays(radio_station_ids)
    return nil if query.count.zero?

    build_lifecycle_stats(query)
  end

  def days_on_air
    return 0 if air_plays.count.zero?

    first_play = air_plays.minimum(:broadcasted_at)
    last_play = air_plays.maximum(:broadcasted_at)
    (last_play.to_date - first_play.to_date).to_i + 1
  end

  def still_playing?(within_days: 7)
    return false if air_plays.count.zero?

    air_plays.where('broadcasted_at >= ?', within_days.days.ago).exists?
  end

  def dormant?(inactive_days: 30)
    return true if air_plays.count.zero?

    !air_plays.where('broadcasted_at >= ?', inactive_days.days.ago).exists?
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

  def build_lifecycle_stats(query)
    first_play = query.minimum(:broadcasted_at)
    last_play = query.maximum(:broadcasted_at)
    total_plays = query.count
    days_active = (last_play.to_date - first_play.to_date).to_i + 1
    unique_days_played = query.select('DATE(broadcasted_at)').distinct.count

    {
      first_play: first_play,
      last_play: last_play,
      total_plays: total_plays,
      days_since_first_play: (Time.zone.today - first_play.to_date).to_i,
      days_since_last_play: (Time.zone.today - last_play.to_date).to_i,
      days_active: days_active,
      unique_days_played: unique_days_played,
      average_plays_per_day: (total_plays.to_f / days_active).round(2),
      play_consistency: (unique_days_played.to_f / days_active * 100).round(1)
    }
  end
end
