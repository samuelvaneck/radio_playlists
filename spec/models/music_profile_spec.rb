# frozen_string_literal: true

# == Schema Information
#
# Table name: music_profiles
#
#  id               :bigint           not null, primary key
#  acousticness     :decimal(5, 4)
#  danceability     :decimal(5, 4)
#  energy           :decimal(5, 4)
#  instrumentalness :decimal(5, 4)
#  liveness         :decimal(5, 4)
#  speechiness      :decimal(5, 4)
#  tempo            :decimal(6, 2)
#  valence          :decimal(5, 4)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  song_id          :bigint           not null
#
# Indexes
#
#  index_music_profiles_on_song_id  (song_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (song_id => songs.id)
#
require 'rails_helper'

RSpec.describe MusicProfile do
  describe 'associations' do
    it { is_expected.to belong_to(:song) }
  end

  describe 'validations' do
    subject { create(:music_profile) }

    it { is_expected.to validate_uniqueness_of(:song_id) }
  end

  describe '#high_feature?' do
    let(:music_profile) { build(:music_profile, danceability: 0.7, liveness: 0.5, speechiness: 0.4) }

    context 'when feature exceeds threshold' do
      it 'returns true for danceability above 0.5' do
        expect(music_profile.high_feature?(:danceability)).to be true
      end

      it 'returns true for speechiness above 0.33' do
        expect(music_profile.high_feature?(:speechiness)).to be true
      end
    end

    context 'when feature is below threshold' do
      it 'returns false for liveness below 0.8' do
        expect(music_profile.high_feature?(:liveness)).to be false
      end
    end

    context 'when feature is nil' do
      let(:music_profile) { build(:music_profile, danceability: nil) }

      it 'returns false' do
        expect(music_profile.high_feature?(:danceability)).to be false
      end
    end
  end

  describe '.attribute_descriptions' do
    it 'returns the ATTRIBUTE_DESCRIPTIONS hash' do
      expect(described_class.attribute_descriptions).to eq(MusicProfile::ATTRIBUTE_DESCRIPTIONS)
    end
  end
end
