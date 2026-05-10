# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArtistTimelineBuilder, type: :service do
  let(:artist) { create(:artist, name: 'Daft Punk', id_on_musicbrainz: '056e4f3e-d505-4dad-8ec1-d04f521cbb56') }
  let(:builder) { described_class.new(artist) }
  let(:wikidata_id) { 'Q4936' }

  let(:mb_result) do
    MusicBrainz::ArtistTimelineFetcher::Result.new(
      events: [
        { 'category' => 'formation', 'date' => '1993', 'title' => 'Daft Punk formed', 'source' => 'musicbrainz' },
        { 'category' => 'album_released', 'date' => '2001-03-12', 'title' => 'Discovery', 'source' => 'musicbrainz' },
        { 'category' => 'dissolution', 'date' => '2021-02-22', 'title' => 'Daft Punk disbanded', 'source' => 'musicbrainz' }
      ],
      wikidata_id: wikidata_id
    )
  end

  let(:wikidata_events) do
    [
      { 'category' => 'formation', 'date' => '1993', 'title' => 'Daft Punk formed', 'source' => 'wikidata' },
      { 'category' => 'notable_work', 'date' => '2013-05-17', 'title' => 'Random Access Memories', 'source' => 'wikidata' },
      { 'category' => 'award', 'date' => '2014-01-26', 'title' => 'Grammy Award for Album of the Year', 'source' => 'wikidata' }
    ]
  end

  before do
    allow(MusicBrainz::ArtistTimelineFetcher).to receive(:new).with(artist.id_on_musicbrainz).and_return(
      instance_double(MusicBrainz::ArtistTimelineFetcher, call: mb_result)
    )
    allow(Wikipedia::WikidataTimelineFinder).to receive(:new).and_return(
      instance_double(Wikipedia::WikidataTimelineFinder, call: wikidata_events)
    )
  end

  describe '#call' do
    context 'when artist has a MusicBrainz ID' do
      it 'returns a payload with artist metadata and merged events', :aggregate_failures do
        result = builder.()
        expect(result['artist']).to eq('Daft Punk')
        expect(result['musicbrainz_id']).to eq(artist.id_on_musicbrainz)
        expect(result['wikidata_id']).to eq(wikidata_id)
        expect(result['events']).to be_an(Array)
      end

      it 'dedupes overlapping events from MusicBrainz and Wikidata' do
        result = builder.()
        formations = result['events'].select { |e| e['category'] == 'formation' }
        expect(formations.size).to eq(1)
      end

      it 'sorts events chronologically' do
        result = builder.()
        dates = result['events'].map { |e| e['date'] }
        expect(dates).to eq(dates.sort)
      end

      it 'includes events from both sources', :aggregate_failures do
        sources = builder.().fetch('events').map { |e| e['source'] }.uniq
        expect(sources).to include('musicbrainz')
        expect(sources).to include('wikidata')
      end
    end

    context 'when artist has no MusicBrainz ID' do
      let(:artist) { create(:artist, name: 'Unknown', id_on_musicbrainz: nil) }

      it 'returns an empty events array without calling external services', :aggregate_failures do
        result = builder.()
        expect(result['events']).to eq([])
        expect(result['musicbrainz_id']).to be_nil
        expect(MusicBrainz::ArtistTimelineFetcher).not_to have_received(:new)
      end
    end

    context 'when MusicBrainz returns no Wikidata link' do
      let(:mb_result) do
        MusicBrainz::ArtistTimelineFetcher::Result.new(
          events: [{ 'category' => 'formation', 'date' => '1993', 'title' => 'Daft Punk formed', 'source' => 'musicbrainz' }],
          wikidata_id: nil
        )
      end

      it 'still returns MusicBrainz events without querying Wikidata', :aggregate_failures do
        result = builder.()
        expect(result['events'].size).to eq(1)
        expect(Wikipedia::WikidataTimelineFinder).not_to have_received(:new)
      end
    end

    context 'when LLM_TIMELINE_ENABLED is false' do
      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('LLM_TIMELINE_ENABLED', 'false').and_return('false')
        allow(Llm::TimelineEventEnricher).to receive(:new)
      end

      it 'skips the LLM enricher and returns plain events' do
        builder.()
        expect(Llm::TimelineEventEnricher).not_to have_received(:new)
      end
    end

    context 'when LLM_TIMELINE_ENABLED is true and Wikipedia article is available' do
      let(:enricher_double) { instance_double(Llm::TimelineEventEnricher) }
      let(:enriched_events) { mb_result.events.map { |e| e.merge('summary' => 'fake', 'notable' => true) } }

      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('LLM_TIMELINE_ENABLED', 'false').and_return('true')
        allow(Wikipedia::ArtistFinder).to receive(:new).and_return(
          instance_double(Wikipedia::ArtistFinder, get_info: { 'content' => 'Daft Punk formed in 1993...' })
        )
        allow(Llm::TimelineEventEnricher).to receive(:new).and_return(enricher_double)
        allow(enricher_double).to receive(:call).and_return(enriched_events)
      end

      it 'enriches events with summary and notable' do
        result = builder.()
        expect(result['events'].first).to include('summary' => 'fake', 'notable' => true)
      end
    end

    context 'when LLM_TIMELINE_ENABLED is true but Wikipedia article is missing' do
      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('LLM_TIMELINE_ENABLED', 'false').and_return('true')
        allow(Wikipedia::ArtistFinder).to receive(:new).and_return(
          instance_double(Wikipedia::ArtistFinder, get_info: nil)
        )
        allow(Llm::TimelineEventEnricher).to receive(:new)
      end

      it 'returns plain events without calling the LLM enricher' do
        builder.()
        expect(Llm::TimelineEventEnricher).not_to have_received(:new)
      end
    end
  end
end
