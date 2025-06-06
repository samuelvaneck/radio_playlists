# frozen_string_literal: true

# == Schema Information
#
# Table name: playlists
#
#  id               :bigint           not null, primary key
#  song_id          :bigint
#  radio_station_id :bigint
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  broadcasted_at   :datetime
#  scraper_import   :boolean          default(FALSE)
#

FactoryBot.define do
  factory :playlist, class: 'Playlist' do
    broadcasted_at { Faker::Time.between(from: DateTime.now - 1, to: DateTime.now) }
    radio_station { create(:radio_station) }
    song { create(:song) }

    after(:build) do |playlist|
      song = playlist.song
      radio_station = playlist.radio_station
      song.radio_stations << radio_station unless song.radio_stations.include?(radio_station)
    end
  end
end
