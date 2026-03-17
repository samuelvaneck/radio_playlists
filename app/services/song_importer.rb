# frozen_string_literal: true

class SongImporter
  include SongImporter::Concerns::AudioRecognition
  include SongImporter::Concerns::TrackFinding
  include SongImporter::Concerns::AirPlayCreation
  include SongImporter::Concerns::ArtistUpdating

  attr_reader :radio_station, :import_logger

  def initialize(radio_station:)
    @radio_station = radio_station
    @import_logger = SongImportLogger.new(radio_station:)
  end

  def import
    safe_start_log
    @played_song = scrape_song_with_enrichment_fallback || recognize_song

    if @played_song.blank?
      Broadcaster.no_importing_song
      @import_logger.skip_log(reason: 'No song scraped or recognized')
      return false
    elsif artist_name.blank?
      Broadcaster.no_importing_artists
      @import_logger.skip_log(reason: 'No artist name found')
      return false
    elsif illegal_word_in_title
      Broadcaster.illegal_word_in_title(title:)
      @import_logger.skip_log(reason: "Illegal word in title: #{title}")
      return false
    elsif artists.nil? || song.nil?
      Broadcaster.no_artists_or_song(title:, radio_station_name: @radio_station.name)
      @import_logger.skip_log(reason: 'No artists or song could be extracted')
      return false
    end

    # Fetch and log Deezer/iTunes data for enrichment
    deezer_track
    itunes_track

    create_air_play
  rescue StandardError => e
    ExceptionNotifier.notify(e)
    Broadcaster.error_during_import(error_message: e.message, radio_station_name: @radio_station.name)
    @import_logger.fail_log(reason: e.message)
    nil
  ensure
    clear_instance_variables
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

  def broadcasted_at
    @broadcasted_at ||= @played_song.broadcasted_at
  end

  def artists
    @artists ||= TrackExtractor::ArtistsExtractor.new(played_song: @played_song, track:).extract
  end

  def song
    @song ||= TrackExtractor::SongExtractor.new(played_song: @played_song, track:, artists:).extract
  end

  def scrape_song_with_enrichment_fallback
    scraped = scrape_song
    return nil if scraped.nil?

    @played_song = scraped
    return scraped if track.present?

    # Scraper data couldn't be enriched, try recognizer instead
    @import_logger.skip_log(reason: "Scraped song '#{scraped.artist_name} - #{scraped.title}' could not be enriched, falling back to recognizer")
    clear_track_data
    recognized = recognize_song
    return recognized if recognized && !same_song?(scraped, recognized)

    # Recognizer also failed, use scraper data as last resort
    clear_track_data
    @played_song = scraped
    scraped
  end

  def same_song?(scraped, recognized)
    artist_similarity = JaroWinkler.similarity(scraped.artist_name.to_s.downcase, recognized.artist_name.to_s.downcase) * 100
    title_similarity = JaroWinkler.similarity(scraped.title.to_s.downcase, recognized.title.to_s.downcase) * 100
    artist_similarity >= 80 && title_similarity >= 70
  end

  def scrape_song
    return nil if @radio_station.url.blank? || @radio_station.processor.blank?

    scrapper = "TrackScraper::#{@radio_station.processor.camelcase}".constantize.new(@radio_station)
    return nil unless scrapper.last_played_song

    @import_logger.log_scraping(scrapper, raw_response: scrapper.raw_response)
    scrapper
  end

  def illegal_word_in_title
    # 2 single quotes, reklame/reclame/nieuws/pingel and 2 dots
    title.match?(/'{2,}|(reklame|reclame|nieuws|pingel)|\.{2,}/i)
  end

  def scraper_import
    @scraper_import ||= @played_song.is_a?(TrackScraper)
  end

  def artists_names
    Array.wrap(artists).map(&:name).join(', ')
  end

  def artists_ids_to_s
    Array.wrap(artists).map(&:id).join(' ')
  end

  ### check if any song played last hour matches the song we are importing
  def any_song_matches?
    @matching = SongImporter::Matcher.new(radio_station: @radio_station, song: @song).matches_any_played_last_hour?
  end

  def safe_start_log
    @import_logger.start_log
  rescue StandardError => e
    Rails.logger.error("Failed to create song import log: #{e.message}")
  end

  def clear_track_data
    @track = @spotify_track = @deezer_track = @itunes_track = nil
    @title = @artist_name = @spotify_url = @isrc_code = @broadcasted_at = nil
    @artists = @song = @scraper_import = nil
  end

  def clear_instance_variables
    @played_song = nil
    clear_track_data
    @importer = @matching = nil
  end
end
