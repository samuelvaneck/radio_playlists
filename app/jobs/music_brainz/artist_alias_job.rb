# frozen_string_literal: true

module MusicBrainz
  class ArtistAliasJob
    include Sidekiq::Job
    sidekiq_options queue: 'low'

    def perform(artist_id)
      artist = Artist.find_by(id: artist_id)
      return if artist.blank?

      artist.fetch_aka_names
    end
  end
end
