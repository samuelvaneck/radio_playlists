# frozen_string_literal: true

# == Schema Information
#
# Table name: radio_stations
#
#  id                  :bigint           not null, primary key
#  name                :string
#  genre               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  url                 :text
#  processor           :string
#  stream_url          :string
#  last_played_song_id :integer
#  slug                :string
#  country_code        :string
#

FactoryBot.define do
  factory :radio_station do
    name { Faker::Name.name }
    url { Faker::Internet.domain_name(subdomain: true, domain: 'example') }
    processor { ['npo_api_processor', 'talpa_api_processor', 'qmusic_api_processor', 'scraper'].sample }
  end

  factory :radio_1, parent: :radio_station do
    name { 'Radio 1' }
    url { 'https://www.nporadio1.nl/api/tracks' }
    processor { 'npo_api_processor' }
  end

  factory :radio_2, parent: :radio_station do
    name { 'Radio 2' }
    url { 'https://www.nporadio2.nl/api/tracks' }
    processor { 'npo_api_processor' }
  end

  factory :radio_3_fm, parent: :radio_station do
    name { 'Radio 3FM' }
    url { 'https://www.npo3fm.nl/api/tracks' }
    processor { 'npo_api_processor' }
  end

  factory :radio_5, parent: :radio_station do
    name { 'Radio 5' }
    url { 'https://www.nporadio5.nl/api/tracks' }
    processor { 'npo_api_processor' }
  end

  factory :sky_radio, parent: :radio_station do
    name { 'Sky Radio' }
    url { 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22sky-radio%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D' }
    processor { 'talpa_api_processor' }
  end

  factory :radio_veronica, parent: :radio_station do
    name { 'Radio Veronica' }
    url { 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22radio-veronica%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D' }
    processor { 'talpa_api_processor' }
  end

  factory :radio_538, parent: :radio_station do
    name { 'Radio 538' }
    url { 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22radio-538%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D' }
    processor { 'talpa_api_processor' }
  end

  factory :radio_10, parent: :radio_station do
    name { 'Radio 10' }
    url { 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22radio-10%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D' }
    processor { 'talpa_api_processor' }
  end

  factory :qmusic, parent: :radio_station do
    name { 'Qmusic' }
    url { 'https://api.qmusic.nl/2.4/tracks/plays?limit=1&next=true' }
    processor { 'qmusic_api_processor' }
  end

  factory :sublime_fm, parent: :radio_station do
    name { 'Sublime FM' }
    url { 'https://sublime.nl/sublime-playlist/' }
    processor { 'scraper' }
  end

  factory :groot_nieuws_radio, parent: :radio_station do
    name { 'Groot Nieuws Radio' }
    url { 'https://www.grootnieuwsradio.nl/muziek/playlist' }
    processor { 'scraper' }
  end
end
