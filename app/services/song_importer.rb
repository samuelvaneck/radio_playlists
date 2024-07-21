# frozen_string_literal: true

class SongImporter
  attr_reader :radio_station
  def initialize(radio_station:)
    @radio_station = radio_station
  end

  def import
    @played_song = recognize_song || scrape_song
    if @played_song.blank?
      Broadcaster.no_importing_song
      return false
    elsif artist_name.blank?
      Broadcaster.no_importing_artists
      return false
    elsif illegal_word_in_title
      Broadcaster.illegal_word_in_title(title:)
      return false
    elsif !song_recognized_twice?
      Broadcaster.not_recognized_twice(title:, artist_name:, radio_station_name: @radio_station.name)
      return false
    elsif artists.nil? || song.nil?
      Broadcaster.no_artists_or_song(title:, radio_station_name: @radio_station.name)
      return false
    end

    create_playlist
  rescue StandardError => e
    Sentry.capture_exception(e)
    Broadcaster.error_during_import(error_message: e.message, radio_station_name: @radio_station.name)
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
    @track ||= TrackExtractor::SpotifyTrackFinder.new(played_song: @played_song).find
  end

  def recognize_song
    recognizer = SongRecognizer.new(@radio_station)
    return nil unless recognizer.recognized?

    recognizer
  end

  def scrape_song
    return nil if @radio_station.url.blank? || @radio_station.processor.blank?

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
    added_playlist = Playlist.add_playlist(@radio_station, song, broadcasted_at, scraper_import)
    @radio_station.update_last_added_playlist_ids(added_playlist.id)
    song.update_artists(artists) if different_artists?

    Broadcaster.song_added(title: song.title, song_id: song.id, artists_names:, artist_ids: artists_ids_to_s, radio_station_name: @radio_station.name)
  end

  def different_artists?
    @song.artist_ids.sort != Array.wrap(@artists).map(&:id).sort
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
end
