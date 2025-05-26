# == Schema Information
#
# Table name: tags
#
#  id            :bigint           not null, primary key
#  counter       :integer          default(0)
#  name          :string           not null
#  taggable_type :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  taggable_id   :bigint           not null
#
# Indexes
#
#  index_tags_on_name_and_taggable_id_and_taggable_type  (name,taggable_id,taggable_type) UNIQUE
#  index_tags_on_taggable                                (taggable_type,taggable_id)
#
class Tag < ApplicationRecord
  belongs_to :taggable, polymorphic: true
end
