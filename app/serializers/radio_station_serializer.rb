# frozen_string_literal: true

# == Schema Information
#
# Table name: radio_stations
#
#  id                      :bigint           not null, primary key
#  country_code            :string
#  direct_stream_url       :string
#  genre                   :string
#  last_added_air_play_ids :jsonb
#  name                    :string
#  processor               :string
#  slug                    :string
#  stream_url              :string
#  url                     :text
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
class RadioStationSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :name, :slug, :stream_url, :country_code
end
