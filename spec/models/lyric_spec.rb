# frozen_string_literal: true

# == Schema Information
#
# Table name: lyrics
#
#  id          :bigint           not null, primary key
#  enriched_at :datetime
#  language    :string(8)
#  sentiment   :decimal(3, 2)
#  source      :string           default("lrclib"), not null
#  source_url  :string
#  themes      :string           default([]), is an Array
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  song_id     :bigint           not null
#  source_id   :string
#
# Indexes
#
#  index_lyrics_on_enriched_at  (enriched_at)
#  index_lyrics_on_sentiment    (sentiment)
#  index_lyrics_on_song_id      (song_id) UNIQUE
#  index_lyrics_on_themes       (themes) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (song_id => songs.id)
#
require 'rails_helper'

RSpec.describe Lyric do
  describe 'associations' do
    it { is_expected.to belong_to(:song) }
  end

  describe 'validations' do
    subject { create(:lyric) }

    it { is_expected.to validate_uniqueness_of(:song_id) }

    it 'rejects sentiment above 1' do
      lyric = build(:lyric, sentiment: 1.5)
      expect(lyric).not_to be_valid
    end

    it 'rejects sentiment below -1' do
      lyric = build(:lyric, sentiment: -1.5)
      expect(lyric).not_to be_valid
    end

    it 'allows nil sentiment' do
      lyric = build(:lyric, sentiment: nil)
      expect(lyric).to be_valid
    end
  end

  describe '#stale?' do
    it 'is true when enriched_at is nil' do
      expect(build(:lyric, enriched_at: nil)).to be_stale
    end

    it 'is true when enriched_at is older than STALE_AFTER' do
      expect(build(:lyric, enriched_at: 100.days.ago)).to be_stale
    end

    it 'is false when enriched_at is recent' do
      expect(build(:lyric, enriched_at: 1.day.ago)).not_to be_stale
    end
  end

  describe '.stale' do
    let!(:fresh_lyric) { create(:lyric, enriched_at: 1.day.ago) }
    let!(:stale_lyric) { create(:lyric, enriched_at: 100.days.ago) }
    let!(:never_lyric) { create(:lyric, enriched_at: nil) }

    it 'includes lyrics older than STALE_AFTER and those never enriched', :aggregate_failures do
      ids = described_class.stale.pluck(:id)
      expect(ids).to include(stale_lyric.id, never_lyric.id)
      expect(ids).not_to include(fresh_lyric.id)
    end
  end

  describe '#plain_lyrics' do
    it 'returns nil when source_id is blank' do
      lyric = build(:lyric, source_id: nil)
      expect(lyric.plain_lyrics).to be_nil
    end

    context 'when source_id is present' do
      let(:lyric) { create(:lyric, source: 'lrclib', source_id: '12345') }

      before do
        allow_any_instance_of(Lyrics::LrclibFinder).to receive(:fetch_by_id) # rubocop:disable RSpec/AnyInstance
                                                         .with('12345').and_return(plain_lyrics: 'Verse 1')
      end

      it 'fetches plain lyrics from LRCLIB' do
        expect(lyric.plain_lyrics).to eq('Verse 1')
      end

      it 'returns nil when LRCLIB returns nothing' do
        allow_any_instance_of(Lyrics::LrclibFinder).to receive(:fetch_by_id) # rubocop:disable RSpec/AnyInstance
                                                         .and_return(nil)
        expect(lyric.plain_lyrics).to be_nil
      end
    end
  end
end
