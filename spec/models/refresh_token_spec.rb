# frozen_string_literal: true

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
require 'rails_helper'

describe RefreshToken, type: :model do
  let(:admin) { create(:admin) }
  let(:session_id) { SecureRandom.hex(16) }

  describe 'associations' do
    it { is_expected.to belong_to(:admin) }
  end

  describe 'callbacks' do
    let(:refresh_token) { create(:refresh_token, admin:, session_id:) }

    it 'generates a token before creation' do
      expect(refresh_token.token).to be_present
    end

    it 'sets an expiration date before creation' do
      expect(refresh_token.expires_at).to be_within(1.second).of(2.weeks.from_now)
    end
  end

  describe '#expired?' do
    let(:refresh_token) { create(:refresh_token, admin:, expires_at:, session_id:) }

    context 'when the token is expired' do
      let(:expires_at) { 1.day.ago }

      it 'returns true' do
        expect(refresh_token.expired?).to be true
      end
    end

    context 'when the token is not expired' do
      let(:expires_at) { 1.day.from_now }

      it 'returns false' do
        expect(refresh_token.expired?).to be false
      end
    end
  end
end
