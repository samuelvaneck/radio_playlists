# frozen_string_literal: true

class YoutubeScrapeImportJob
  include Sidekiq::Worker

  def perform
    radio_station_url.each do |url|
      if response(url).blank?
        Rails.logger.info 'No response on request'
        return nil
      end
      if id_on_youtube.blank?
        Rails.logger.info 'No id on youtube'
        return nil
      end

      song = Song.find_by(id_on_spotify:)
      song ||= Song.find_by(fullname: "#{artist_name} #{song_title}")

      if song.present? && song.id_on_youtube.blank?
        Rails.logger.info("Updating #{artist_name} #{song_title} with id_on_youtube: #{id_on_youtube}")
        song.update(id_on_youtube:)
      end

      clear_instance_variables
    end
  rescue StandardError => e
    Rails.logger.error "Error in YoutubeImportJob: #{e.message}"
    ExceptionNotifier.notify_new_relic(e, 'YoutubeScrapeImportJob')
    nil
  ensure
    clear_instance_variables
  end

  private

  def radio_station_url
    %w[https://api.qmusic.nl/2.4/tracks/plays?limit=1&next=true
      https://api.qmusic.be/2.4/tracks/plays?limit=1&next=true
      https://api.joe.nl/2.0/tracks/plays?limit=1
      https://api.joe.be/2.0/tracks/plays?limit=1]
  end

  def clear_instance_variables
    @response = nil
    @make_request = nil
    @artist_name = nil
    @song_title = nil
    @id_on_spotify = nil
    @youtube_video_id = nil
  end

  def response(url)
    @response ||= make_request(url)
  end

  def make_request(url)
    @make_request ||= TrackScraper::QmusicApiProcessor.new(nil).make_request(url)
  end

  def artist_name
    @artist_name ||= @response&.dig('played_tracks', 0, 'artist', 'name').titleize
  end

  def song_title
    @song_title ||= @response.dig('played_tracks', 0, 'title').titleize
  end

  def id_on_spotify
    spotify_url = @response.dig('played_tracks', 0, 'spotify_url')
    return nil if spotify_url.blank?

    @id_on_spotify ||= spotify_url('/').last
  end

  def id_on_youtube
    return @youtube_video_id if @youtube_video_id.present?

    youtube_video = @response.dig('played_tracks', 0, 'videos')
                             .find { |video| video['type'] == 'youtube' }
    return nil if youtube_video.blank?

    @youtube_video_id = youtube_video['id']
  end
end
