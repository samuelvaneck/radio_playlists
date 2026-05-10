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
class ArtistTimeline < ApplicationRecord
  DEFAULT_STALE_AFTER = 30.days

  belongs_to :artist

  validates :artist_id, uniqueness: true

  scope :stale, ->(after: DEFAULT_STALE_AFTER) { where(arel_table[:fetched_at].lt(after.ago)) }
  scope :fresh, ->(after: DEFAULT_STALE_AFTER) { where(arel_table[:fetched_at].gteq(after.ago)) }

  def stale?(after: DEFAULT_STALE_AFTER)
    fetched_at.nil? || fetched_at < after.ago
  end

  def needs_refresh?(after: DEFAULT_STALE_AFTER)
    stale?(after: after)
  end
end
