# frozen_string_literal: true

FactoryBot.define do
  factory :artist_timeline do
    artist
    events { [] }
    musicbrainz_id { nil }
    wikidata_id { nil }
    llm_enriched { false }
    fetched_at { Time.current }
  end
end
