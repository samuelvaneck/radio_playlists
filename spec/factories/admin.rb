FactoryBot.define do
  factory :admin do
    email { Faker::Internet.email }
    password { 'password123' }
  end
end
