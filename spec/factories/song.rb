# frozen_string_literal: true

# == Schema Information
#
# Table name: songs
#
#  id                                :bigint           not null, primary key
#  title                             :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  fullname                          :text
#  spotify_song_url                  :string
#  spotify_artwork_url               :string
#  id_on_spotify                     :string
#  isrc                              :string
#  spotify_preview_url               :string
#  cached_chart_positions            :jsonb
#  cached_chart_positions_updated_at :datetime
#  id_on_youtube                     :string
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


    after(:build) do |song|
      song.artists << build(:artist) if song.artists.blank?
      song.fullname =  "#{song.artists.map(&:name).join(' ')} #{song.title}"
    end
  end
end
