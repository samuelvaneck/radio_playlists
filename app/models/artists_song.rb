# frozen_string_literal: true

# == Schema Information
#
# Table name: artists_songs
#
#  artist_id :bigint           not null
#  song_id   :bigint           not null
#
# Indexes
#
#  index_artists_songs_on_artist_id              (artist_id)
#  index_artists_songs_on_artist_id_and_song_id  (artist_id,song_id) UNIQUE
#  index_artists_songs_on_song_id                (song_id)
#

class ArtistsSong < ApplicationRecord
  belongs_to :artist
  belongs_to :song

  validates :song_id, uniqueness: { scope: :artist_id }
end
