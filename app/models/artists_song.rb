# frozen_string_literal: true

# join table artist songs
class ArtistsSong < ApplicationRecord
  belongs_to :artist
  belongs_to :song

  validates :song_id, uniqueness: { scope: :artist_id }
end
