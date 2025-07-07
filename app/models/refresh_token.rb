# == Schema Information
#
# Table name: refresh_tokens
#
#  id         :bigint           not null, primary key
#  expires_at :datetime
#  token      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  admin_id   :bigint           not null
#  session_id :string           not null
#
# Indexes
#
#  index_refresh_tokens_on_admin_id    (admin_id)
#  index_refresh_tokens_on_session_id  (session_id) UNIQUE
#  index_refresh_tokens_on_token       (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (admin_id => admins.id)
#
class RefreshToken < ApplicationRecord
  before_create :generate_token

  belongs_to :admin

  validates :token, uniqueness: true

  def expired?
    Time.current >= expires_at
  end

  private

  def generate_token
    self.token = SecureRandom.hex(64)
    self.expires_at ||= 2.weeks.from_now
  end
end
