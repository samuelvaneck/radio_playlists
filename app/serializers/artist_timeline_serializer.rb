# frozen_string_literal: true

class ArtistTimelineSerializer
  include FastJsonapi::ObjectSerializer

  set_type :artist_timeline

  attributes :events, :musicbrainz_id, :wikidata_id, :llm_enriched, :fetched_at

  attribute :attribution do |_object|
    {
      'wikidata' => {
        'license' => 'CC0',
        'url' => 'https://www.wikidata.org/wiki/Wikidata:Licensing'
      },
      'musicbrainz' => {
        'license' => 'CC0 (data) / CC BY-NC-SA (non-PD content)',
        'url' => 'https://musicbrainz.org/doc/About/Data_License'
      },
      'wikipedia' => {
        'license' => 'CC BY-SA',
        'url' => 'https://en.wikipedia.org/wiki/Wikipedia:Reusing_Wikipedia_content',
        'note' => 'Used as grounding source for LLM-generated event summaries.'
      }
    }
  end
end
