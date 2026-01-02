# frozen_string_literal: true

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
