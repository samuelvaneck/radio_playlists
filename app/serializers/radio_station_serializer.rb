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
class RadioStationSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :name, :slug, :stream_url, :country_code
end
