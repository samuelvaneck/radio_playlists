# frozen_string_literal: true

# == Schema Information
#
# Table name: artists_songs
#
#  song_id   :bigint           not null
#  artist_id :bigint           not null
#

class ArtistsSong < ApplicationRecord
  belongs_to :artist
  belongs_to :song

  validates :song_id, uniqueness: { scope: :artist_id }
end
