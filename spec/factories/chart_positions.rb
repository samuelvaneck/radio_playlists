# == Schema Information
#
# Table name: chart_positions
#
#  id                :bigint           not null, primary key
#  counts            :bigint           default(0), not null
#  positianable_type :string           not null
#  position          :bigint           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  chart_id          :bigint           not null
#  positianable_id   :bigint           not null
#
# Indexes
#
#  index_chart_positions_on_chart_id                               (chart_id)
#  index_chart_positions_on_positianable_id_and_positianable_type  (positianable_id,positianable_type)
#
# Foreign Keys
#
#  fk_rails_...  (chart_id => charts.id)
#
FactoryBot.define do
  factory :chart_position do
  end
end
