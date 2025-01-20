# frozen_string_literal: true

class YoutubeApiImportJob
  include Sidekiq::Worker

  def perform
    song = first_song_without_youtube_id
    if song.blank?
      Rails.logger.info 'No song without youtube id found'
      return nil
    end

    id_on_youtube = Youtube::Search.new(args_for_youtube_search(song)).find_id
    id_on_youtube = '' if id_on_youtube.blank?

    Rails.logger.info("Updating #{song.title} with id_on_youtube: #{id_on_youtube}")
    song.update(id_on_youtube:)
  rescue StandardError => e
    Rails.logger.error "Error in YoutubeApiImportJob: #{e.message}"
    ExceptionNotifier.notify_new_relic(e, 'YoutubeApiImportJob')
    nil
  end

  private

  def first_song_without_youtube_id
    last_song_chart = Chart.latest_song_chart
    song_ids = last_song_chart.chart_positions.pluck(:positianable_id)
    Song.where(id: song_ids, id_on_youtube: nil).order(:id).first
  end

  def args_for_youtube_search(song)
    { artists: song.artists.pluck(:name).join(' '), title: song.title }
  end
end
