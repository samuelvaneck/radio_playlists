# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArtistTimelineEnrichmentJob do
  let(:artist) { create(:artist, name: 'Daft Punk', id_on_musicbrainz: '056e4f3e-d505-4dad-8ec1-d04f521cbb56') }
  let(:job) { described_class.new }
  let(:builder_payload) do
    {
      'artist' => 'Daft Punk',
      'artist_id' => artist.id,
      'musicbrainz_id' => '056e4f3e-d505-4dad-8ec1-d04f521cbb56',
      'wikidata_id' => 'Q185828',
      'events' => [
        { 'category' => 'formation', 'date' => '1993', 'title' => 'Daft Punk formed', 'source' => 'musicbrainz' }
      ]
    }
  end

  before do
    builder = instance_double(ArtistTimelineBuilder, call: builder_payload)
    allow(ArtistTimelineBuilder).to receive(:new).and_return(builder)
  end

  describe '#perform' do
    context 'when artist has a MusicBrainz ID and no existing timeline' do
      it 'creates a new timeline row', :aggregate_failures do
        expect { job.perform(artist.id) }.to change(ArtistTimeline, :count).by(1)
        timeline = artist.reload.timeline
        expect(timeline.events).to eq(builder_payload['events'])
        expect(timeline.wikidata_id).to eq('Q185828')
        expect(timeline.fetched_at).to be_within(5.seconds).of(Time.current)
      end
    end

    context 'when artist already has a timeline' do
      let!(:existing) { create(:artist_timeline, artist: artist, fetched_at: 60.days.ago, events: []) }

      it 'updates the existing row instead of creating a new one', :aggregate_failures do
        expect { job.perform(artist.id) }.not_to change(ArtistTimeline, :count)
        existing.reload
        expect(existing.events).to eq(builder_payload['events'])
        expect(existing.fetched_at).to be_within(5.seconds).of(Time.current)
      end
    end

    context 'when artist is missing' do
      it 'returns without calling the builder' do
        job.perform(-1)
        expect(ArtistTimelineBuilder).not_to have_received(:new)
      end
    end

    context 'when artist has no MusicBrainz ID' do
      let(:artist) { create(:artist, name: 'Unknown', id_on_musicbrainz: nil) }

      it 'returns without calling the builder' do
        job.perform(artist.id)
        expect(ArtistTimelineBuilder).not_to have_received(:new)
      end
    end

    context 'when builder returns LLM-enriched events' do
      let(:builder_payload) do
        {
          'artist' => 'Daft Punk', 'artist_id' => artist.id, 'musicbrainz_id' => 'mb', 'wikidata_id' => 'wd',
          'events' => [{ 'category' => 'formation', 'date' => '1993', 'title' => 't', 'source' => 'mb', 'summary' => 'x', 'notable' => true }]
        }
      end

      it 'sets llm_enriched to true' do
        job.perform(artist.id)
        expect(artist.reload.timeline.llm_enriched).to be(true)
      end
    end
  end

  describe '.enqueue_stale' do
    let!(:stale) { create(:artist, id_on_musicbrainz: 'mb-stale') }
    let!(:fresh) { create(:artist, id_on_musicbrainz: 'mb-fresh') }
    let!(:no_mbid) { create(:artist, id_on_musicbrainz: nil) }

    before do
      create(:artist_timeline, artist: stale, fetched_at: 60.days.ago)
      create(:artist_timeline, artist: fresh, fetched_at: 1.day.ago)
    end

    it 'enqueues only artists whose timelines are stale or missing', :aggregate_failures do
      allow(described_class).to receive(:perform_in)
      described_class.enqueue_stale
      expect(described_class).to have_received(:perform_in).with(anything, stale.id)
      expect(described_class).not_to have_received(:perform_in).with(anything, fresh.id)
      expect(described_class).not_to have_received(:perform_in).with(anything, no_mbid.id)
    end
  end
end
