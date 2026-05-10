# frozen_string_literal: true

# == Schema Information
#
# Table name: artist_timelines
#
#  id             :bigint           not null, primary key
#  events         :jsonb            not null
#  fetched_at     :datetime
#  llm_enriched   :boolean          default(FALSE), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  artist_id      :bigint           not null
#  musicbrainz_id :string
#  wikidata_id    :string
#
# Indexes
#
#  index_artist_timelines_on_artist_id   (artist_id) UNIQUE
#  index_artist_timelines_on_fetched_at  (fetched_at)
#
# Foreign Keys
#
#  fk_rails_...  (artist_id => artists.id)
#
require 'rails_helper'

RSpec.describe ArtistTimeline, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:artist) }
  end

  describe 'validations' do
    subject { build(:artist_timeline) }

    it { is_expected.to validate_uniqueness_of(:artist_id) }
  end

  describe '#stale?' do
    context 'when fetched_at is nil' do
      let(:timeline) { build(:artist_timeline, fetched_at: nil) }

      it 'returns true' do
        expect(timeline.stale?).to be(true)
      end
    end

    context 'when fetched_at is older than the threshold' do
      let(:timeline) { build(:artist_timeline, fetched_at: 31.days.ago) }

      it 'returns true' do
        expect(timeline.stale?).to be(true)
      end
    end

    context 'when fetched_at is within the threshold' do
      let(:timeline) { build(:artist_timeline, fetched_at: 1.day.ago) }

      it 'returns false' do
        expect(timeline.stale?).to be(false)
      end
    end
  end

  describe '.stale and .fresh scopes' do
    let!(:fresh_timeline) { create(:artist_timeline, fetched_at: 1.day.ago) }
    let!(:stale_timeline) { create(:artist_timeline, fetched_at: 60.days.ago) }

    it 'separates rows by fetched_at threshold', :aggregate_failures do
      expect(described_class.stale).to contain_exactly(stale_timeline)
      expect(described_class.fresh).to contain_exactly(fresh_timeline)
    end
  end
end
