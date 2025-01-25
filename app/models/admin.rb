class Admin < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :validatable, :trackable,
         :jwt_authenticatable, jwt_revocation_strategy: self
end
