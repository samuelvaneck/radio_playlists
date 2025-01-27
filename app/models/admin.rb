class Admin < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  after_create :set_uuid

  private

  def set_uuid
    self.uuid = SecureRandom.uuid
  end
end
