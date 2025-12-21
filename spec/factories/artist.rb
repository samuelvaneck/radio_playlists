# frozen_string_literal: true

# == Schema Information
#
# Table name: artists
#
#  id                 :bigint           not null, primary key
#  genre              :string
#  id_on_spotify      :string
#  image              :string
#  instagram_url      :string
#  name               :string
#  spotify_artist_url :string
#  spotify_artwork_url:string
#  website_url        :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_artists_on_name  (name)
#

FactoryBot.define do
  factory :artist do
    name { Faker::Music.band }
  end
end
