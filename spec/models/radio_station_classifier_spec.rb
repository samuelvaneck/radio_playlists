# == Schema Information
#
# Table name: radio_station_classifiers
#
#  id               :bigint           not null, primary key
#  radio_station_id :bigint           not null
#  danceable        :integer          default(0)
#  energy           :integer          default(0)
#  speech           :integer          default(0)
#  acoustic         :integer          default(0)
#  instrumental     :integer          default(0)
#  live             :integer          default(0)
#  valence          :integer          default(0)
#  day_part         :string           not null
#  tempo            :decimal(5, 2)    default(0.0)
#  counter          :integer          default(0)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
require 'rails_helper'

RSpec.describe RadioStationClassifier, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
