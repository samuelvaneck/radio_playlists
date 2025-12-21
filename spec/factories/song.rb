# frozen_string_literal: true

# == Schema Information
#
# Table name: songs
#
#  id                     :bigint           not null, primary key
#  id_on_spotify          :string
#  id_on_youtube          :string
#  isrc                   :string
#  release_date           :date
#  release_date_precision :string
#  search_text            :text
#  spotify_artwork_url    :string
#  spotify_preview_url    :string
#  spotify_song_url       :string
#  title                  :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_songs_on_release_date  (release_date)
#  index_songs_on_search_text   (search_text)
#

FactoryBot.define do
  factory :song do
    title { Faker::Music::RockBand.song }
    isrc { Faker::Alphanumeric.alphanumeric(number: 12).upcase }
    id_on_spotify { Faker::Alphanumeric.alphanumeric(number: 22) }
    spotify_song_url { Faker::Internet.url(host: 'open.spotify.com', path: "/track/#{id_on_spotify}") }
    spotify_artwork_url { Faker::Internet.url(host: 'i.scdn.co', path: '/image/random') }
    spotify_preview_url { Faker::Internet.url(host: 'p.scdn.co', path: '/mp3-preview/random') }
    id_on_youtube { Faker::Alphanumeric.alphanumeric(number: 11) }
    artists { [build(:artist)] }

    after(:build) do |song|
      song.artists << build(:artist) if song.artists.blank?
    end
  end
end
