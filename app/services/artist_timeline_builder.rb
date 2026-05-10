# frozen_string_literal: true

class ArtistTimelineBuilder
  def initialize(artist, language: 'en')
    @artist = artist
    @language = language
  end

  def call
    return empty_payload if @artist.id_on_musicbrainz.blank?

    mb_result = MusicBrainz::ArtistTimelineFetcher.new(@artist.id_on_musicbrainz).()
    wikidata_events = fetch_wikidata_events(mb_result.wikidata_id)
    events = merge_and_sort(mb_result.events, wikidata_events)
    events = enrich_with_llm(events) if llm_enrichment_enabled?

    {
      'artist' => @artist.name,
      'artist_id' => @artist.id,
      'musicbrainz_id' => @artist.id_on_musicbrainz,
      'wikidata_id' => mb_result.wikidata_id,
      'events' => events
    }
  end

  private

  def fetch_wikidata_events(wikidata_id)
    return [] if wikidata_id.blank?

    Wikipedia::WikidataTimelineFinder.new(language: @language).(wikidata_id)
  end

  def llm_enrichment_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('LLM_TIMELINE_ENABLED', 'false'))
  end

  def enrich_with_llm(events)
    return events if events.empty?

    article_text = fetch_article_text
    return events if article_text.blank?

    Llm::TimelineEventEnricher.new(events: events, article_text: article_text, artist_name: @artist.name).()
  end

  def fetch_article_text
    info = Wikipedia::ArtistFinder.new(language: @language).get_info(@artist.name, include_general_info: false)
    info&.dig('content').presence || info&.dig('summary').presence
  end

  def merge_and_sort(mb_events, wikidata_events)
    deduped = (mb_events + wikidata_events).each_with_object({}) do |event, acc|
      key = dedupe_key(event)
      acc[key] = event unless acc.key?(key)
    end
    deduped.values.sort_by { |event| sort_key(event) }
  end

  def dedupe_key(event)
    [year(event['date']), event['category'], event['title'].to_s.downcase.strip]
  end

  def sort_key(event)
    [event['date'].to_s.empty? ? 1 : 0, event['date'].to_s, event['category']]
  end

  def year(date)
    date.to_s[/-?\d{4}/]
  end

  def empty_payload
    {
      'artist' => @artist.name,
      'artist_id' => @artist.id,
      'musicbrainz_id' => nil,
      'wikidata_id' => nil,
      'events' => []
    }
  end
end
