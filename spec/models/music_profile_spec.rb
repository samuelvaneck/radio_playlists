# frozen_string_literal: true

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
