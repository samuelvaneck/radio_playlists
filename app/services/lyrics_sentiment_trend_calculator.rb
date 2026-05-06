# frozen_string_literal: true

# Time-bucketed average lyrics sentiment for a radio station's airplays.
# Returns one row per bucket: { period_start, average_sentiment, play_count }.
class LyricsSentimentTrendCalculator
  BUCKET_EXPRESSIONS = {
    hour: Arel.sql("date_trunc('hour', air_plays.broadcasted_at)"),
    day: Arel.sql("date_trunc('day', air_plays.broadcasted_at)"),
    month: Arel.sql("date_trunc('month', air_plays.broadcasted_at)"),
    year: Arel.sql("date_trunc('year', air_plays.broadcasted_at)")
  }.freeze
  AVG_EXPR = Arel.sql('AVG(lyrics.sentiment)::float')
  COUNT_EXPR = Arel.sql('COUNT(*)')

  def initialize(radio_station:, period: '4_weeks')
    @radio_station = radio_station
    @period = period.presence || '4_weeks'
  end

  def calculate
    return [] if start_time.nil?

    bucket_expr = BUCKET_EXPRESSIONS.fetch(bucket_granularity)

    rows = AirPlay
             .where(radio_station: @radio_station, broadcasted_at: start_time..)
             .joins(song: :lyric)
             .where.not(lyrics: { sentiment: nil })
             .group(bucket_expr)
             .pluck(bucket_expr, AVG_EXPR, COUNT_EXPR)

    rows
      .map { |bucket_at, avg, count| { period_start: bucket_at, average_sentiment: avg.round(3), play_count: count } }
      .sort_by { |b| b[:period_start] }
  end

  private

  def start_time
    @start_time ||= begin
      duration = PeriodParser.parse_duration(@period)
      duration ? duration.ago : @radio_station.air_plays.minimum(:broadcasted_at)
    end
  end

  def bucket_granularity
    return :year if @period == 'all'

    case @period
    when /year/ then :month
    when /month/, /week/ then :day
    when /day/ then :hour
    else :day
    end
  end
end
