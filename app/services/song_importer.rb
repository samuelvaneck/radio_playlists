# frozen_string_literal: true

class SongImporter
  CLEARED_IVARS = %i[
    @played_song @artists @song @track @spotify_track @deezer_track @itunes_track @scraper_import
  ].freeze

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
    @played_song = scrape_song || recognize_song
    return false if skip_import?

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

  delegate :title, :artist_name, :spotify_url, :isrc_code, :broadcasted_at, to: :@played_song, allow_nil: true

  def artists
    @artists ||= TrackExtractor::ArtistsExtractor.new(played_song: @played_song, track:).extract
  end

  def song
    @song ||= TrackExtractor::SongExtractor.new(played_song: @played_song, track:, artists:).extract
  end

  def scrape_song
    return nil if @radio_station.url.blank? || @radio_station.processor.blank?

    scrapper = "TrackScraper::#{@radio_station.processor.camelcase}".constantize.new(@radio_station)
    return nil unless scrapper.last_played_song

    @import_logger.log_scraping(scrapper, raw_response: scrapper.raw_response)
    scrapper
  end

  def skip_import?
    if @played_song.blank?
      Broadcaster.no_importing_song
      @import_logger.skip_log(reason: 'No song scraped or recognized')
      return true
    elsif artist_name.blank?
      Broadcaster.no_importing_artists
      @import_logger.skip_log(reason: 'No artist name found')
      return true
    elsif illegal_word_in_title
      Broadcaster.illegal_word_in_title(title:)
      @import_logger.skip_log(reason: "Illegal word in title: #{title}")
      return true
    elsif recently_imported?
      @import_logger.skip_log(reason: 'Duplicate: same scraped data recently imported')
      return true
    elsif radio_program?
      @import_logger.skip_log(reason: "Detected as radio program: #{title}")
      return true
    elsif artists.nil? || song.nil?
      Broadcaster.no_artists_or_song(title:, radio_station_name: @radio_station.name)
      @import_logger.skip_log(reason: 'No artists or song could be extracted')
      return true
    end

    false
  end

  def illegal_word_in_title
    # 2 single quotes, reklame/reclame/nieuws/pingel and 2 dots
    title.match?(/'{2,}|(reklame|reclame|nieuws|pingel)|\.{2,}/i)
  end

  def recently_imported?
    return false unless scraper_import

    SongImportLog.where(radio_station: @radio_station, broadcasted_at: broadcasted_at)
      .where(scraped_artist: artist_name, scraped_title: title)
      .where.not(id: @import_logger.log&.id)
      .where(created_at: 1.hour.ago..)
      .exists?
  end

  def radio_program?
    return false unless scraper_import
    return false unless artist_resembles_station?
    return false if track.present?

    detector = Llm::ProgramDetector.new(
      artist_name: artist_name,
      title: title,
      radio_station_name: @radio_station.name
    )
    is_program = detector.program?
    @import_logger.log_llm(action: 'program_detection', raw_response: detector.raw_response)
    is_program
  end

  def artist_resembles_station?
    normalize = ->(s) { s.downcase.gsub(/[^a-z0-9]/, '') }
    station = normalize.(@radio_station.name)
    artist = normalize.(artist_name)

    station == artist || station.include?(artist) || artist.include?(station)
  end

  def scraper_import
    @scraper_import ||= @played_song.is_a?(TrackScraper)
  end

  def artists_names
    Array.wrap(artists).map(&:name).join(', ')
  end

  def safe_start_log
    @import_logger.start_log
  rescue StandardError => e
    Rails.logger.error("Failed to create song import log: #{e.message}")
  end

  def clear_instance_variables
    CLEARED_IVARS.each do |ivar|
      remove_instance_variable(ivar) if instance_variable_defined?(ivar)
    end
  end
end
