# frozen_string_literal: true

# Top lyric themes for a radio station's airplays in a period.
# Returns one row per theme: { theme, play_count, share }.
# `share` is the fraction of plays-with-themes that contain this theme;
# because plays can carry multiple themes, shares can sum to > 1.0.
class LyricsThemeBreakdownCalculator
  TOP_LIMIT = 10
  THEME_EXPR = Arel.sql('unnest(lyrics.themes)')
  COUNT_EXPR = Arel.sql('COUNT(*)')

  def initialize(radio_station:, period: '4_weeks')
    @radio_station = radio_station
    @period = period.presence || '4_weeks'
  end

  def calculate
    return [] if start_time.nil?

    counts = airplays_in_range
               .group(THEME_EXPR)
               .pluck(THEME_EXPR, COUNT_EXPR)
    return [] if counts.empty?

    total = total_plays_with_themes
    return [] if total.zero?

    counts
      .map { |theme, count| build_row(theme, count, total) }
      .sort_by { |t| [-t[:play_count], t[:theme_en]] }
      .first(TOP_LIMIT)
  end

  private

  def build_row(theme, count, total)
    {
      theme_en: theme,
      theme_nl: Lyrics::ThemeTranslator.translate(theme),
      play_count: count,
      share: (count.to_f / total).round(3)
    }
  end

  def airplays_in_range
    AirPlay
      .where(radio_station: @radio_station, broadcasted_at: start_time..)
      .joins(song: :lyric)
  end

  def total_plays_with_themes
    @total_plays_with_themes ||= airplays_in_range
                                   .where('array_length(lyrics.themes, 1) > 0')
                                   .count
  end

  def start_time
    @start_time ||= begin
      duration = PeriodParser.parse_duration(@period)
      duration ? duration.ago : @radio_station.air_plays.minimum(:broadcasted_at)
    end
  end
end
