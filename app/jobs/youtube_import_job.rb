# frozen_string_literal: true

class YoutubeImportJob
  include Sidekiq::Worker

  def perform
    if radio_station.blank?
      Rails.logger.info 'Radio station not found'
      return nil
    end
    if make_request.blank?
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
      Rails.logger.info "Updating #{artist_name} #{song_title} with id_on_youtube: #{id_on_youtube}"
      song.update(id_on_youtube:)
    end
  ensure
    @radio_station = nil
    @make_request = nil
    @artist_name = nil
    @song_title = nil
    @id_on_spotify = nil
    @youtube_video_id = nil
  end

  private

  def radio_station
    @radio_station ||= RadioStation.find_by(name: 'Qmusic')
  end

  def make_request
    @make_request ||= TrackScraper::QmusicApiProcessor.new(radio_station).make_request
  end

  def artist_name
    @artist_name ||= make_request.dig('played_tracks', 0, 'artist', 'name').titleize
  end

  def song_title
    @song_title ||= make_request.dig('played_tracks', 0, 'title').titleize
  end

  def id_on_spotify
    @id_on_spotify ||= make_request.dig('played_tracks', 0, 'spotify_url').split('/').last
  end

  def id_on_youtube
    @youtube_video_id ||= make_request.dig('played_tracks', 0, 'videos', 0, 'id')
  end
end
