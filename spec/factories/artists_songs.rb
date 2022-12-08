# frozen_string_literal: true

# == Schema Information
#
# Table name: artists_songs
#
#  song_id   :bigint           not null
#  artist_id :bigint           not null
#

FactoryBot.define do
  factory :artists_song do
    association :artist, factory: :artist
    association :song, factory: :song
  end
end
