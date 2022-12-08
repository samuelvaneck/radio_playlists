# frozen_string_literal: true

# == Schema Information
#
# Table name: artists
#
#  id                  :bigint           not null, primary key
#  name                :string
#  image               :string
#  genre               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  spotify_artist_url  :string
#  spotify_artwork_url :string
#  id_on_spotify       :string
#

FactoryBot.define do
  factory :artist do
    name { Faker::Music.band }
  end
end
