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
class Lyric < ApplicationRecord
  STALE_AFTER = 90.days

  belongs_to :song

  validates :song_id, uniqueness: true
  validates :sentiment, numericality: { greater_than_or_equal_to: -1, less_than_or_equal_to: 1, allow_nil: true }

  scope :stale, -> { where(enriched_at: nil).or(where(enriched_at: ...STALE_AFTER.ago)) }

  def stale?
    enriched_at.nil? || enriched_at < STALE_AFTER.ago
  end
end
