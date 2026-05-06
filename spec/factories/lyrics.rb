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
