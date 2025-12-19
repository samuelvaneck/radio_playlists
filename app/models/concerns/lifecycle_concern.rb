# frozen_string_literal: true

module LifecycleConcern
  extend ActiveSupport::Concern

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
