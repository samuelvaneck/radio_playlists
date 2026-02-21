# frozen_string_literal: true

class SongExternalIdsEnrichmentJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 3

  # Enqueue jobs for all songs missing external IDs
  def self.enqueue_all
    scope = Song
              .where(id_on_deezer: nil)
              .or(Song.where(id_on_itunes: nil))
              .or(Song.where(isrcs: []).where.not(isrc: [nil, '']))

    scope.find_each { |song| perform_async(song.id) }
  end

  # Enrich a single song with Deezer and iTunes IDs
  def perform(song_id)
    song = Song.find_by(id: song_id)
    return if song.blank?

    song.enrich_with_external_services
  end
end
