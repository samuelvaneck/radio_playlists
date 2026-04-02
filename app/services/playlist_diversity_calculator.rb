# frozen_string_literal: true

# Calculates playlist diversity metrics for a radio station over a given time period.
#
# Uses three established diversity/concentration indices from information theory and economics:
#
# 1. Gini coefficient (0-1) — Measures inequality in airplay distribution.
#    0 = all songs played equally, 1 = one song gets all plays.
#    Commercial radio typically scores 0.7-0.8 (ACM recommendation diversity studies).
#
# 2. Shannon entropy — Measures variety and unpredictability of song selection.
#    Normalized to [0,1] by dividing by ln(unique_songs) for cross-station comparability.
#    Higher = more diverse playlist.
#
# 3. Herfindahl-Hirschman Index (0-10000) — Sum of squared market shares.
#    Used in economics to measure market concentration; applied here to airplay share.
#    Lower = more diverse, higher = more concentrated on few songs.
#
# Usage:
#   calculator = PlaylistDiversityCalculator.new(
#     radio_station: station,
#     start_time: 1.week.ago,
#     end_time: Time.current
#   )
#   result = calculator.calculate
#
# References:
#   - Stirling (2007): "A General Framework for Analysing Diversity"
#   - ACM (2023): https://dl.acm.org/doi/10.1145/3608487
class PlaylistDiversityCalculator
  DIVERSITY_THRESHOLDS = {
    gini: { high: 0.6, moderate: 0.4 },
    normalized_entropy: { high: 0.7, moderate: 0.4 },
    hhi: { high: 1500, moderate: 2500 }
  }.freeze

  def initialize(radio_station:, start_time: nil, end_time: nil)
    @radio_station = radio_station
    @start_time = start_time || 4.weeks.ago
    @end_time = end_time || Time.current
  end

  def calculate
    return nil if play_counts.empty?

    {
      radio_station: { id: @radio_station.id, name: @radio_station.name, slug: @radio_station.slug },
      period: { start_time: @start_time.iso8601, end_time: @end_time.iso8601 },
      metrics: {
        gini_coefficient: gini_coefficient,
        shannon_entropy: shannon_entropy,
        normalized_entropy: normalized_entropy,
        hhi: hhi,
        label: diversity_label
      },
      sample: { unique_songs: unique_songs_count, total_plays: total_plays },
      top_songs: top_songs
    }
  end

  private

  def gini_coefficient
    return 0.0 if unique_songs_count <= 1

    sorted = sorted_counts
    n = sorted.size
    numerator = sorted.each_with_index.sum { |count, i| (i + 1) * count }

    ((2.0 * numerator) / (n * sorted.sum) - (n + 1).to_f / n).round(4)
  end

  def shannon_entropy
    return 0.0 if total_plays.zero?

    -shares.sum { |share| share * Math.log(share) }.round(4)
  end

  def normalized_entropy
    return 0.0 if unique_songs_count <= 1

    (shannon_entropy / Math.log(unique_songs_count)).round(4)
  end

  def hhi
    shares.sum { |share| (share * 100)**2 }.round(2)
  end

  def diversity_label
    ne = normalized_entropy
    if ne >= DIVERSITY_THRESHOLDS[:normalized_entropy][:high]
      'highly diverse'
    elsif ne >= DIVERSITY_THRESHOLDS[:normalized_entropy][:moderate]
      'moderately diverse'
    else
      'highly repetitive'
    end
  end

  def top_songs(limit: 10)
    play_counts
      .sort_by { |_, count| -count }
      .first(limit)
      .map do |song_id, count|
        song = songs_by_id[song_id]
        next unless song

        {
          song_id: song.id,
          title: song.title,
          artists: song.artists.map(&:name),
          play_count: count,
          share: (count.to_f / total_plays * 100).round(2)
        }
      end
      .compact
  end

  def shares
    @shares ||= play_counts.values.map { |count| count.to_f / total_plays }
  end

  def sorted_counts
    @sorted_counts ||= play_counts.values.sort
  end

  def unique_songs_count
    play_counts.size
  end

  def total_plays
    @total_plays ||= play_counts.values.sum
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
                       .where(id: play_counts.keys.first(10))
                       .index_by(&:id)
  end
end
