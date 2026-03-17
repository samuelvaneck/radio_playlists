# frozen_string_literal: true

module SongImporter::Concerns
  module ArtistUpdating
    extend ActiveSupport::Concern

    private

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
  end
end
