# frozen_string_literal: true

class SongImporter
  attr_reader :radio_station
  def initialize(radio_station:)
    @radio_station = radio_station
  end

  def import
    @played_song = recognize_song || scrape_song
    if @played_song.blank?
      Rails.logger.info('No importing song')
      return false
    elsif artist_name.blank?
      Rails.logger.info('No importing artists')
      return false
    elsif illegal_word_in_title
      Rails.logger.info("Found illegal word in #{title}")
      return false
    elsif !song_recognized_twice?
      Rails.logger.info("#{title} from #{artist_name} recognized once on #{@radio_station.name}")
      return false
    elsif artists.nil? || song.nil?
      Rails.logger.info("No artists or song found for #{title} on #{@radio_station.name}")
      false
    end

    create_playlist
  rescue StandardError => e
    Sentry.capture_exception(e)
    Rails.logger.error "Error while importing song from #{@radio_station.name}: #{e.message}"
    nil
  end

  private

  def title
    @title ||= @played_song.title
  end

  def artist_name
    @artist_name ||= @played_song.artist_name
  end

  def spotify_url
    @spotify_url ||= @played_song.spotify_url
  end

  def isrc_code
    @isrc_code ||= @played_song.isrc_code
  end

  def broadcast_timestamp
    @broadcast_timestamp ||= @played_song.broadcast_timestamp
  end

  def artists
    @artists ||= TrackExtractor::ArtistsExtractor.new(played_song: @played_song, track: spotify_track).extract
  end

  def song
    @song ||= TrackExtractor::SongExtractor.new(played_song: @played_song, track: spotify_track, artists:).extract
  end

  def spotify_track
    @track ||= TrackExtractor::SpotifyTrackFinder.new(played_song: @played_song).find
  end

  def recognize_song
    recognizer = SongRecognizer.new(@radio_station)
    return nil unless recognizer.recognized?

    recognizer
  end

  def scrape_song
    scrapper = "TrackScraper::#{@radio_station.processor.camelcase}".constantize.new(@radio_station)
    return nil unless scrapper.last_played_song

    scrapper
  end

  def illegal_word_in_title
    # 2 single qoutes, reklame/reclame/nieuws/pingel and 2 dots
    if title.match(/'{2,}|(reklame|reclame|nieuws|pingel)|\.{2,}/i)
      true
    else
      false
    end
  end

  def song_recognized_twice?
    SongRecognizerCache.new(radio_station_id: @radio_station.id, title:, artist_name:).recognized_twice?
  end

  def scraper_import
    @scraper_import ||= @played_song.is_a?(TrackScraper)
  end

  def create_playlist
    @importer = if scraper_import
                  SongImporter::ScraperImporter.new(radio_station: @radio_station, artists:, song:)
                else
                  SongImporter::RecognizerImporter.new(radio_station: @radio_station, artists:, song:)
                end
    if @importer.may_import_song?
      add_song
    else
      @importer.broadcast_error_message
    end
  end

  def add_song
    Playlist.add_playlist(@radio_station, song, broadcast_timestamp, scraper_import)
    song.update_artists(@artists) if different_artists?

    Rails.logger.info "*** Saved #{song.title} (#{song.id}) from #{artists_names} (#{artists_ids_to_s}) on #{@radio_station.name}! ***"
  end

  def different_artists?
    @song.artist_ids.sort != Array.wrap(@artists).map(&:id).sort
  end

  def artists_names
    Array.wrap(@artists).map(&:name).join(', ')
  end

  def artists_ids_to_s
    Array.wrap(@artists).map(&:id).join(' ')
  end

  ### check if any song played last hour matches the song we are importing
  def any_song_matches?
    @matching = SongImporter::Matcher.new(radio_station: @radio_station, song: @song).matches_any_played_last_hour?
  end
end
