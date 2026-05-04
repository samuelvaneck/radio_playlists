# frozen_string_literal: true

class AvgSongGapCalculationJob
  include Sidekiq::Job
  sidekiq_options queue: 'compute'

  def perform
    RadioStation.find_each(&:calculate_avg_song_gap_per_hour)
  end
end
