# frozen_string_literal: true

FactoryBot.define do
  factory :lyric do
    song
    sentiment { 0.42 }
    themes { %w[love nostalgia] }
    language { 'en' }
    source { 'lrclib' }
    source_id { '390' }
    source_url { 'https://lrclib.net/api/get/390' }
    enriched_at { Time.current }
  end
end
