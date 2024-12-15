# frozen_string_literal: true

# == Schema Information
#
# Table name: songs
#
#  id                     :bigint           not null, primary key
#  title                  :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  fullname               :text
#  spotify_song_url       :string
#  spotify_artwork_url    :string
#  id_on_spotify          :string
#  isrc                   :string
#  spotify_preview_url    :string
#  cached_chart_positions :jsonb
#

FactoryBot.define do
  factory :song do
    title { Faker::Music::UmphreysMcgee.song }
    isrc { 'GBARL1800805' }
    id_on_spotify { '1elj43HiTzMyQwawBazPCQ' }

    after(:build) do |song|
      song.fullname = "#{song.artists.map(&:name).join(' ')} #{song.fullname}"
    end

    trait :filled do
      after(:build) do |song|
        song.artists << create(:artist) if song.artists.blank?
        song.fullname = "#{song.artists.map(&:name).join(' ')} #{song.fullname}"
      end
    end
  end
end
