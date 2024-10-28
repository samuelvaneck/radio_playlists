# == Schema Information
#
# Table name: chart_positions
#
#  id                :bigint           not null, primary key
#  position          :bigint           not null
#  positianable_id   :bigint           not null
#  positianable_type :string           not null
#  chart_id          :bigint           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
require 'rails_helper'

RSpec.describe ChartPosition, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
