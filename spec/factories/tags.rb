# == Schema Information
#
# Table name: tags
#
#  id            :bigint           not null, primary key
#  name          :string           not null
#  counter       :integer          default(0)
#  taggable_type :string           not null
#  taggable_id   :bigint           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
FactoryBot.define do
  factory :tag do
    name { "MyString" }
    taggable { nil }
  end
end
