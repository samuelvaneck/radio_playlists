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
class ChartPosition < ApplicationRecord
  belongs_to :positianable, polymorphic: true
  belongs_to :chart

  validates :position, :positianable_id, :positianable_type, presence: true
end
