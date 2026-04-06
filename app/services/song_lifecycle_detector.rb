# frozen_string_literal: true

# Detects the current lifecycle phase of a song based on its airplay trajectory.
#
# Songs follow distinct lifecycle patterns on radio: rise → peak → plateau → decline.
# Research shows songs peak on radio in ~10 weeks (vs ~5 weeks on streaming), and radio
# airplay can extend a song's streaming life.
#
# Phases:
#   - rise:    Weekly plays trending upward, not yet reached peak
#   - peak:    Currently at or near maximum weekly play count (within last 2 weeks)
#   - plateau: Post-peak, stable play rate (within 20% of trailing average)
#   - decline: Post-peak, play rate dropping (below 80% of trailing average)
#
# Also calculates "days to peak" — how long it took the song to reach maximum airplay.
#
# Usage:
#   detector = SongLifecycleDetector.new(song, radio_station_ids: [1, 2])
#   result = detector.detect  # => { phase: :peak, days_to_peak: 42, ... }
#
# References:
#   - "Predicting the Product Life Cycle of Songs on the Radio" (Springer, 2021)
#   - Billboard analysis on radio chart longevity
class SongLifecycleDetector
  TRAILING_WEEKS = 4
  PEAK_RECENCY_WEEKS = 2
  PLATEAU_THRESHOLD = 0.20
  MINIMUM_WEEKS = 3

  def initialize(song, radio_station_ids: nil)
    @song = song
    @radio_station_ids = radio_station_ids
  end

  def detect
    return nil if weekly_counts.size < 2

    {
      phase: current_phase,
      days_to_peak: days_to_peak,
      weeks_since_first_play: weekly_counts.size,
      peak_week: peak_week_date.strftime('%Y-%m-%d'),
      peak_count: peak_count,
      current_weekly_average: current_weekly_average.round(1),
      weekly_counts: formatted_weekly_counts
    }
  end

  private

  def current_phase
    return :rise if rising?
    return :peak if at_peak?
    return :plateau if plateau?

    :decline
  end

  def rising?
    return false if weeks_since_peak.negative?

    # Song hasn't peaked yet: peak is in the most recent week
    peak_index = counts_array.index(peak_count)
    peak_index == counts_array.size - 1 && counts_array.size >= 2
  end

  def at_peak?
    weeks_since_peak <= PEAK_RECENCY_WEEKS && current_weekly_average >= peak_count * 0.8
  end

  def plateau?
    return false if trailing_average.zero?

    ratio = current_weekly_average / trailing_average
    ratio.between?(1 - PLATEAU_THRESHOLD, 1 + PLATEAU_THRESHOLD)
  end

  def days_to_peak
    return 0 if weekly_counts.empty?

    ((peak_week_date - first_week_date) / 1.day).to_i
  end

  def weeks_since_peak
    return 0 if weekly_counts.empty?

    peak_index = counts_array.index(peak_count)
    counts_array.size - 1 - peak_index
  end

  def current_weekly_average
    recent = counts_array.last([TRAILING_WEEKS, counts_array.size].min)
    recent.sum.to_f / recent.size
  end

  def trailing_average
    return 0.0 if counts_array.size < TRAILING_WEEKS + 1

    trailing = counts_array[-(TRAILING_WEEKS + 1)..-2] || counts_array
    trailing.sum.to_f / trailing.size
  end

  def peak_week_date
    @peak_week_date ||= weekly_counts.max_by { |_, count| count }.first
  end

  def peak_count
    @peak_count ||= weekly_counts.values.max
  end

  def first_week_date
    weekly_counts.keys.min
  end

  def counts_array
    @counts_array ||= sorted_weekly_counts.map(&:last)
  end

  def formatted_weekly_counts
    sorted_weekly_counts.to_h { |date, count| [date.strftime('%Y-%m-%d'), count] }
  end

  def sorted_weekly_counts
    @sorted_weekly_counts ||= weekly_counts.sort_by(&:first)
  end

  def weekly_counts
    @weekly_counts ||= begin
      scope = @song.air_plays.confirmed.where.not(broadcasted_at: nil)
      scope = scope.where(radio_station_id: @radio_station_ids) if @radio_station_ids.present?

      scope
        .group(Arel.sql("DATE_TRUNC('week', broadcasted_at)"))
        .count
        .reject { |key, _| key.nil? }
    end
  end
end
