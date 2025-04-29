# frozen_string_literal: true

class YoutubeScrapeImportJob
  include Sidekiq::Worker

  def perform
    radio_station_url.each do |url|
      @response = response(url)
      next nil if @response.blank?
      next nil if id_on_youtube.blank?

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
    @song = nil
  end

  def response(url)
    make_request(url)
  end

  def make_request(url)
    response = connection.get(url) do |req|
      req.headers['Content-Type'] = 'application/json'
    end
    response.body.with_indifferent_access
  end

  def artist_name
    @response&.dig(:played_tracks, 0, :artist, :name)&.titleize
  end

  def song_title
    @response&.dig(:played_tracks, 0, :title)&.titleize
  end

  def id_on_spotify
    spotify_url = @response&.dig(:played_tracks, 0, :spotify_url)
    return nil if spotify_url.blank?

    spotify_url.split('/').last
  end

  def id_on_youtube
    youtube_video = @response&.dig(:played_tracks, 0, :videos)
                             &.find { |video| video[:type] == 'youtube' }
    return nil if youtube_video.blank?

    youtube_video['id']
  end

  def song
    Song.find_by(id_on_spotify:) || Song.find_by(search_text: "#{artist_name} #{song_title}")
  end

  def connection
    Faraday.new do |conn|
      conn.response :json
      conn.adapter :net_http
    end
  end
end
