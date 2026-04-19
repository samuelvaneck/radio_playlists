# frozen_string_literal: true

# Rolls back a single SongImportLog by ID: destroys the linked airplay,
# destroys the linked song if no other airplays reference it, and marks
# the log as failed with a rollback reason.
#
# Guards:
#  - Skips song deletion if the song still has airplays from other stations.
#  - Skips song deletion if the song has chart positions (keeps charts intact).
class SongImportLogRollback
  ROLLBACK_REASON = 'rolled_back'

  attr_reader :results

  def initialize(log_id, dry_run: true, reason: ROLLBACK_REASON)
    @log_id = log_id
    @dry_run = dry_run
    @reason = reason
    @results = initial_results
  end

  def run
    log = SongImportLog.find_by(id: @log_id)
    return error_result('import log not found') if log.blank?

    ActiveRecord::Base.transaction do
      rollback_airplay(log)
      rollback_song(log)
      mark_log_rolled_back(log)
    end

    @results
  rescue StandardError => e
    @results[:errors] << e.message
    @results
  end

  private

  def initial_results
    {
      log_id: @log_id,
      air_play_destroyed: false,
      song_destroyed: false,
      song_kept_reason: nil,
      errors: []
    }
  end

  def error_result(message)
    @results[:errors] << message
    @results
  end

  def rollback_airplay(log)
    air_play = log.air_play
    return if air_play.blank?

    @results[:air_play_destroyed] = true
    air_play.destroy! unless @dry_run
  end

  def rollback_song(log)
    song = log.song
    return if song.blank?

    reason = song_kept_reason(song, log.air_play_id)
    if reason.present?
      @results[:song_kept_reason] = reason
      return
    end

    @results[:song_destroyed] = true
    return if @dry_run

    ArtistsSong.where(song_id: song.id).delete_all
    song.destroy!
  end

  def song_kept_reason(song, excluded_air_play_id)
    return 'other_airplays_exist' if other_airplays_exist?(song, excluded_air_play_id)
    return 'has_chart_positions' if song.chart_positions.exists?

    nil
  end

  def other_airplays_exist?(song, excluded_air_play_id)
    scope = AirPlay.where(song_id: song.id)
    scope = scope.where.not(id: excluded_air_play_id) if excluded_air_play_id.present?
    scope.exists?
  end

  def mark_log_rolled_back(log)
    return if @dry_run

    log.update!(status: :failed, failure_reason: @reason, song_id: nil, air_play_id: nil)
  end
end
