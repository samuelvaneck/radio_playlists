# frozen_string_literal: true

class SongImporter
  attr_reader :radio_station, :import_logger

  def initialize(radio_station:)
    @radio_station = radio_station
    @import_logger = SongImportLogger.new(radio_station:)
  end

  def import
    safe_start_log
    @played_song = recognize_song || scrape_song

    if @played_song.blank?
      Broadcaster.no_importing_song
      @import_logger.skip_log(reason: 'No song recognized or scraped')
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
    ExceptionNotifier.notify_new_relic(e)
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
    @artists ||= TrackExtractor::ArtistsExtractor.new(played_song: @played_song, track: spotify_track).extract
  end

  def song
    @song ||= TrackExtractor::SongExtractor.new(played_song: @played_song, track: spotify_track, artists:).extract
  end

  def spotify_track
    @track ||= begin
      track = TrackExtractor::SpotifyTrackFinder.new(played_song: @played_song).find
      @import_logger.log_spotify(track) if track
      track
    end
  end

  def deezer_track
    @deezer_track ||= begin
      track = TrackExtractor::DeezerTrackFinder.new(played_song: @played_song).find
      @import_logger.log_deezer(track) if track&.valid_match?
      track
    end
  end

  def itunes_track
    @itunes_track ||= begin
      track = TrackExtractor::ItunesTrackFinder.new(played_song: @played_song).find
      @import_logger.log_itunes(track) if track&.valid_match?
      track
    end
  end

  def recognize_song
    recognizer = SongRecognizer.new(@radio_station)
    return nil unless recognizer.recognized?

    @import_logger.log_recognition(recognizer)
    recognizer
  end

  def scrape_song
    return nil if @radio_station.url.blank? || @radio_station.processor.blank?

    scrapper = "TrackScraper::#{@radio_station.processor.camelcase}".constantize.new(@radio_station)
    return nil unless scrapper.last_played_song

    @import_logger.log_scraping(scrapper, raw_response: scrapper.raw_response)
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

  def scraper_import
    @scraper_import ||= @played_song.is_a?(TrackScraper)
  end

  def create_air_play
    @importer = if scraper_import
                  SongImporter::ScraperImporter.new(radio_station: @radio_station, artists:, song:)
                else
                  SongImporter::RecognizerImporter.new(radio_station: @radio_station, artists:, song:)
                end
    if @importer.may_import_song?
      add_song
    else
      @importer.broadcast_error_message
      @import_logger.skip_log(reason: 'Song already imported recently or matches last played song')
    end
  end

  def safe_start_log
    @import_logger.start_log
  rescue StandardError => e
    Rails.logger.error("Failed to create song import log: #{e.message}")
  end

  def add_song
    added_air_play = find_or_create_air_play
    finalize_song_import(added_air_play)
  end

  def find_or_create_air_play
    existing_draft = AirPlay.find_draft_for_confirmation(@radio_station, song)

    if existing_draft
      confirm_existing_draft(existing_draft)
    else
      create_new_draft_air_play
    end
  end

  def confirm_existing_draft(draft)
    draft.confirmed!
    Broadcaster.song_confirmed(title: song.title, song_id: song.id, artists_names:, radio_station_name: @radio_station.name)
    draft
  end

  def create_new_draft_air_play
    air_play = AirPlay.add_air_play(@radio_station, song, broadcasted_at, scraper_import)
    Broadcaster.song_draft_created(title: song.title, song_id: song.id, artists_names:, radio_station_name: @radio_station.name)
    air_play
  end

  def finalize_song_import(air_play)
    @import_logger.complete_log(song:, air_play:)
    @radio_station.update_last_added_air_play_ids(air_play.id)
    song.update_artists(artists) if should_update_artists?
    @radio_station.songs << song unless RadioStationSong.exists?(radio_station: @radio_station, song:)
    RadioStationClassifierJob.perform_async(song.id_on_spotify, @radio_station.id)
  end

  def different_artists?
    @song.artist_ids.sort != Array.wrap(@artists).map(&:id).sort
  end

  # Only update artists if the song doesn't have artists with Spotify IDs yet.
  # This prevents race conditions where concurrent imports overwrite each other's artist data.
  def should_update_artists?
    return false unless different_artists?

    # If song has no artists, always update
    return true if @song.artists.blank?

    # If song's existing artists don't have Spotify IDs, update with new data
    # (this means the song was imported without Spotify data initially)
    @song.artists.none? { |artist| artist.id_on_spotify.present? }
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

  def clear_instance_variables
    @played_song = nil
    @title = nil
    @artist_name = nil
    @spotify_url = nil
    @isrc_code = nil
    @broadcasted_at = nil
    @artists = nil
    @song = nil
    @track = nil
    @deezer_track = nil
    @itunes_track = nil
    @scraper_import = nil
    @importer = nil
    @matching = nil
  end
end
