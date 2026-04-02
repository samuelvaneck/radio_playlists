# frozen_string_literal: true

# Calculates exposure saturation for songs on a radio station based on the
# mere exposure effect (Zajonc, 1968).
#
# The mere exposure effect shows an inverted-U relationship between exposure
# frequency and listener preference: repeated exposure increases liking up to
# an optimal point, after which it declines ("boredom threshold"). Less complex
# songs reach peak preference faster but also saturate faster.
#
# For each song, calculates an exposure ratio relative to the station's median
# play frequency, and maps it to an inverted-U (Gaussian) curve to produce a
# saturation index (0-1, where 1 = optimal exposure).
#
# Statuses:
#   - underexposed:       ratio < 0.5 (could benefit from more airplay)
#   - optimal:            ratio 0.5-2.5 (ideal exposure range)
#   - overexposed:        ratio 2.5-4.0 (past optimal, listener fatigue likely)
#   - heavily_overexposed: ratio > 4.0 (significantly past optimal)
#
# Usage:
#   calculator = ExposureSaturationCalculator.new(
#     radio_station: station,
#     start_time: 1.week.ago,
#     end_time: Time.current
#   )
#   result = calculator.calculate
#
# References:
#   - Zajonc (1968): "Attitudinal Effects of Mere Exposure"
#   - Chmiel & Schubert (2017): "Back to the inverted-U for music preference"
#   - Szpunar et al. (2004): "Liking and Memory for Musical Stimuli"
class ExposureSaturationCalculator
  OPTIMAL_RATIO = 1.5
  GAUSSIAN_SPREAD = 1.0

  STATUS_THRESHOLDS = {
    underexposed: 0.5,
    optimal: 2.5,
    overexposed: 4.0
  }.freeze

  def initialize(radio_station:, start_time: nil, end_time: nil)
    @radio_station = radio_station
    @start_time = start_time || 1.week.ago
    @end_time = end_time || Time.current
  end

  def calculate
    return nil if play_counts.empty?

    {
      radio_station: { id: @radio_station.id, name: @radio_station.name, slug: @radio_station.slug },
      period: { start_time: @start_time.iso8601, end_time: @end_time.iso8601 },
      baseline: baseline_stats,
      songs: song_saturation_data,
      overexposed_count: song_saturation_data.count { |s| s[:status].to_s.include?('overexposed') },
      underexposed_count: song_saturation_data.count { |s| s[:status] == :underexposed }
    }
  end

  private

  def baseline_stats
    sorted = play_counts.values.sort
    {
      median_plays: median(sorted),
      mean_plays: (sorted.sum.to_f / sorted.size).round(1),
      std_deviation: std_deviation(sorted).round(1),
      total_songs: sorted.size,
      total_plays: sorted.sum
    }
  end

  def song_saturation_data
    @song_saturation_data ||= begin
      median_plays = median(play_counts.values.sort)
      return [] if median_plays.zero?

      play_counts
        .sort_by { |_, count| -count }
        .map do |song_id, count|
          song = songs_by_id[song_id]
          next unless song

          ratio = count.to_f / median_plays
          {
            song_id: song.id,
            title: song.title,
            artists: song.artists.map(&:name),
            play_count: count,
            plays_per_day: (count.to_f / days_in_period).round(2),
            exposure_ratio: ratio.round(2),
            saturation_index: saturation_index(ratio).round(3),
            status: exposure_status(ratio)
          }
        end
        .compact
    end
  end

  def saturation_index(ratio)
    distance = (ratio - OPTIMAL_RATIO) / GAUSSIAN_SPREAD
    Math.exp(-0.5 * distance**2)
  end

  def exposure_status(ratio)
    if ratio < STATUS_THRESHOLDS[:underexposed]
      :underexposed
    elsif ratio <= STATUS_THRESHOLDS[:optimal]
      :optimal
    elsif ratio <= STATUS_THRESHOLDS[:overexposed]
      :overexposed
    else
      :heavily_overexposed
    end
  end

  def median(sorted_values)
    return 0 if sorted_values.empty?

    mid = sorted_values.size / 2
    if sorted_values.size.odd?
      sorted_values[mid]
    else
      (sorted_values[mid - 1] + sorted_values[mid]) / 2.0
    end
  end

  def std_deviation(values)
    return 0.0 if values.size < 2

    mean = values.sum.to_f / values.size
    variance = values.sum { |v| (v - mean)**2 } / (values.size - 1)
    Math.sqrt(variance)
  end

  def days_in_period
    @days_in_period ||= [(@end_time - @start_time) / 1.day, 1].max
  end

  def play_counts
    @play_counts ||= AirPlay.confirmed
                       .where(radio_station: @radio_station)
                       .where(broadcasted_at: @start_time..@end_time)
                       .group(:song_id)
                       .count
  end

  def songs_by_id
    @songs_by_id ||= Song.includes(:artists)
                       .where(id: play_counts.keys)
                       .index_by(&:id)
  end
end
