# frozen_string_literal: true

module SongImporter::Concerns
  module AirPlayCreation
    extend ActiveSupport::Concern

    private

    def create_air_play
      importer = if scraper_import
                   SongImporter::ScraperImporter.new(radio_station: @radio_station, artists:, song:)
                 else
                   SongImporter::RecognizerImporter.new(radio_station: @radio_station, artists:, song:)
                 end
      if importer.may_import_song?
        add_song
      else
        importer.broadcast_error_message
        @import_logger.skip_log(reason: 'Song already imported recently or matches last played song')
      end
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
        create_new_air_play
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

    def create_new_air_play
      status = auto_confirm? ? :confirmed : :draft
      air_play = AirPlay.add_air_play(@radio_station, song, broadcasted_at, scraper_import, status:)
      if auto_confirm?
        Broadcaster.song_confirmed(title: song.title, song_id: song.id, artists_names:, radio_station_name: @radio_station.name)
      else
        Broadcaster.song_draft_created(title: song.title, song_id: song.id, artists_names:, radio_station_name: @radio_station.name)
      end
      air_play
    end

    def auto_confirm?
      scraper_import || @radio_station.processor.blank?
    end

    def finalize_song_import(air_play)
      @import_logger.complete_log(song:, air_play:)
      @radio_station.update_last_added_air_play_ids(air_play.id)
      song.update_artists(artists) if should_update_artists?
      @radio_station.songs << song unless RadioStationSong.exists?(radio_station: @radio_station, song:)
      persist_scraper_fields
      MusicProfileJob.perform_async(song.id, @radio_station.id)
      SongExternalIdsEnrichmentJob.perform_async(song.id)
      enqueue_artist_external_ids_enrichment
    end

    def enqueue_artist_external_ids_enrichment
      song.artists.each do |artist|
        ArtistExternalIdsEnrichmentJob.perform_async(artist.id) if artist.needs_external_ids_enrichment?
      end
    end

    # Some processors (e.g. QmusicApiProcessor) extract YouTube IDs and artist
    # social URLs that the Spotify/Deezer/iTunes lookups don't provide. Persist
    # them when present and the existing values are blank.
    def persist_scraper_fields
      return unless @played_song.respond_to?(:youtube_id)

      song.update(id_on_youtube: @played_song.youtube_id) if song.id_on_youtube.blank? && @played_song.youtube_id.present?
      update_artist_social_urls
    end

    def update_artist_social_urls
      matched_artist = song.artists.find_by(name: artist_name)
      return if matched_artist.blank?

      updates = {}
      updates[:website_url]   = @played_song.website_url   if matched_artist.website_url.blank?   && @played_song.website_url.present?
      updates[:instagram_url] = @played_song.instagram_url if matched_artist.instagram_url.blank? && @played_song.instagram_url.present?
      matched_artist.update(updates) if updates.any?
    end
  end
end
