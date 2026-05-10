# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Llm::TimelineEventEnricher, type: :service do
  let(:events) do
    [
      { 'category' => 'formation', 'date' => '1993', 'title' => 'Daft Punk formed', 'source' => 'musicbrainz' },
      { 'category' => 'album_released', 'date' => '2001-03-12', 'title' => 'Discovery', 'source' => 'musicbrainz' },
      { 'category' => 'album_released', 'date' => '2002', 'title' => 'Daft Club', 'source' => 'musicbrainz' }
    ]
  end
  let(:article_text) { 'Daft Punk formed in Paris in 1993. Discovery (2001) introduced a more melodic, house-oriented sound.' }
  let(:enricher) { described_class.new(events: events, article_text: article_text, artist_name: 'Daft Punk') }

  describe '#call' do
    context 'when the LLM returns valid enrichments' do
      let(:llm_response) do
        {
          'enrichments' => [
            { 'index' => 0, 'summary' => 'Formed in Paris in 1993.', 'notable' => true },
            { 'index' => 1, 'summary' => 'A melodic, house-oriented album.', 'notable' => true },
            { 'index' => 2, 'summary' => nil, 'notable' => false }
          ]
        }.to_json
      end

      before { allow(enricher).to receive(:chat).and_return(llm_response) }

      it 'merges summary and notable into each event', :aggregate_failures do
        result = enricher.()
        expect(result.size).to eq(3)
        expect(result[0]['summary']).to eq('Formed in Paris in 1993.')
        expect(result[0]['notable']).to be(true)
        expect(result[2]['notable']).to be(false)
      end

      it 'preserves the original event fields' do
        result = enricher.()
        expect(result[1]).to include('category' => 'album_released', 'title' => 'Discovery', 'source' => 'musicbrainz')
      end
    end

    context 'when LLM response is malformed' do
      before { allow(enricher).to receive(:chat).and_return('not json at all') }

      it 'returns the original events unchanged' do
        expect(enricher.()).to eq(events)
      end
    end

    context 'when LLM returns nil' do
      before { allow(enricher).to receive(:chat).and_return(nil) }

      it 'returns the original events unchanged' do
        expect(enricher.()).to eq(events)
      end
    end

    context 'when article text is blank' do
      let(:article_text) { '' }

      it 'returns events without calling the LLM', :aggregate_failures do
        allow(enricher).to receive(:chat)
        expect(enricher.()).to eq(events)
        expect(enricher).not_to have_received(:chat)
      end
    end

    context 'when events list is empty' do
      let(:events) { [] }

      it 'returns the empty list without calling the LLM', :aggregate_failures do
        allow(enricher).to receive(:chat)
        expect(enricher.()).to eq([])
        expect(enricher).not_to have_received(:chat)
      end
    end
  end
end
