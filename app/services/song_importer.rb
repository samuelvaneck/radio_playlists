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
    @artists ||= TrackExtractor::ArtistsExtractor.new(played_song: @played_song, track:).extract
  end

  def song
    @song ||= TrackExtractor::SongExtractor.new(played_song: @played_song, track:, artists:).extract
  end

  def track
    @track ||= spotify_track_if_valid || itunes_track_if_valid || deezer_track_if_valid
  end

  def spotify_track_if_valid
    result = spotify_track
    result&.valid_match? ? result : nil
  end

  def itunes_track_if_valid
    result = itunes_track
    result&.valid_match? ? result : nil
  end

  def deezer_track_if_valid
    result = deezer_track
    result&.valid_match? ? result : nil
  end

  def spotify_track
    @spotify_track ||= begin
      result = TrackExtractor::SpotifyTrackFinder.new(played_song: @played_song).find
      @import_logger.log_spotify(result) if result
      result
    end
  end

  def deezer_track
    @deezer_track ||= begin
      result = TrackExtractor::DeezerTrackFinder.new(played_song: @played_song).find
      @import_logger.log_deezer(result) if result&.valid_match?
      result
    end
  end

  def itunes_track
    @itunes_track ||= begin
      result = TrackExtractor::ItunesTrackFinder.new(played_song: @played_song).find
      @import_logger.log_itunes(result) if result&.valid_match?
      result
    end
  end

  def recognize_song
    output_file = @radio_station.audio_file_path
    audio_stream = build_audio_stream(output_file)

    begin
      audio_stream.capture
    rescue PersistentStream::SegmentReader::NoSegmentError, PersistentStream::SegmentReader::StaleSegmentError => e
      Rails.logger.warn "Persistent segment unavailable for #{@radio_station.name}, falling back to Icecast: #{e.message}"
      audio_stream = build_icecast_stream(output_file)
      audio_stream.capture
    end

    songrec = SongRecognizer.new(@radio_station, audio_stream:, skip_cleanup: true)
    songrec_result = songrec.recognized?
    @import_logger.log_recognition(songrec) if songrec_result

    acoustid = AcoustidRecognizer.new(output_file)
    acoustid.recognized?
    @import_logger.log_acoustid(acoustid)

    songrec_result ? songrec : nil
  ensure
    audio_stream&.delete_file
  end

  def build_audio_stream(output_file)
    return AudioStream::PersistentSegment.new(@radio_station, output_file) if persistent_segment_available?

    build_icecast_stream(output_file)
  end

  def build_icecast_stream(output_file)
    extension = @radio_station.direct_stream_url.split(/\.|-/).last
    if extension.match?(/m3u8/)
      AudioStream::M3u8.new(@radio_station.direct_stream_url, output_file)
    else
      AudioStream::Mp3.new(@radio_station.direct_stream_url, output_file)
    end
  end

  def persistent_segment_available?
    @radio_station.direct_stream_url.present? && PersistentStream::SegmentReader.new(@radio_station).available?
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
    existing_draft = AirPlay.find_draft_for_confirmation(@radio_station, song, broadcasted_at)

    if existing_draft
      confirm_existing_draft(existing_draft)
    else
      create_new_draft_air_play
    end
  end

  def confirm_existing_draft(draft)
    if draft.song_id != song.id
      old_song = draft.song
      draft.update!(song:, broadcasted_at:)
      old_song.cleanup
    end
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
    MusicProfileJob.perform_async(song.id, @radio_station.id)
    SongExternalIdsEnrichmentJob.perform_async(song.id)
  end

  def different_artists?
    @song.artist_ids.sort != Array.wrap(@artists).map(&:id).sort
  end

  # Only update artists if the song doesn't have artists with Spotify IDs yet,
  # OR if the new artists come from the same Spotify track as the song.
  # This prevents race conditions where concurrent imports overwrite each other's artist data,
  # while allowing correction of wrong artists when authoritative Spotify data is available.
  def should_update_artists?
    return false unless different_artists?

    # If song has no artists, always update
    return true if @song.artists.blank?

    # If song's existing artists don't have Spotify IDs, update with new data
    # (this means the song was imported without Spotify data initially)
    return true if @song.artists.none? { |artist| artist.id_on_spotify.present? }

    # If new artists come from a Spotify track that matches the song's stored Spotify ID,
    # allow the update. This corrects wrong artists that were locked in by a previous import.
    new_artists_from_spotify? && matching_spotify_track?
  end

  def new_artists_from_spotify?
    Array.wrap(@artists).any? { |artist| artist.id_on_spotify.present? }
  end

  # Check if the current import's Spotify track matches the song's stored Spotify ID.
  # Uses @track directly (already computed earlier in the import flow) to avoid side effects.
  def matching_spotify_track?
    return false if @track.blank? || !@track.respond_to?(:spotify_song_url) || @track.id.blank?
    return false if @song.id_on_spotify.blank?

    @track.id == @song.id_on_spotify
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
    @spotify_track = nil
    @deezer_track = nil
    @itunes_track = nil
    @scraper_import = nil
    @importer = nil
    @matching = nil
  end
end
