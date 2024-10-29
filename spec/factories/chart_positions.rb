# == Schema Information
#
# Table name: chart_positions
#
#  id                :bigint           not null, primary key
#  position          :bigint           not null
#  counts            :bigint           default(0), not null
#  positianable_id   :bigint           not null
#  positianable_type :string           not null
#  chart_id          :bigint           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
FactoryBot.define do
  factory :chart_position do
    
  end
end
