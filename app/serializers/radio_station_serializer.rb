# frozen_string_literal: true

# == Schema Information
#
# Table name: radio_stations
#
#  id         :bigint           not null, primary key
#  name       :string
#  genre      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  url        :text
#  processor  :string
#  stream_url :string
#
class RadioStationSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :name
end
