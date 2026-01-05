# frozen_string_literal: true

# == Schema Information
#
# Table name: music_profiles
#
#  id               :bigint           not null, primary key
#  acousticness     :decimal(5, 4)
#  danceability     :decimal(5, 4)
#  energy           :decimal(5, 4)
#  instrumentalness :decimal(5, 4)
#  liveness         :decimal(5, 4)
#  speechiness      :decimal(5, 4)
#  tempo            :decimal(6, 2)
#  valence          :decimal(5, 4)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  song_id          :bigint           not null
#
# Indexes
#
#  index_music_profiles_on_song_id  (song_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (song_id => songs.id)
#
FactoryBot.define do
  factory :music_profile do
    song
    danceability { 0.65 }
    energy { 0.72 }
    speechiness { 0.08 }
    acousticness { 0.25 }
    instrumentalness { 0.02 }
    liveness { 0.12 }
    valence { 0.58 }
    tempo { 120.5 }
  end
end
