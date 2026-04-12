# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Llm::QueryTranslator, type: :service do
  let(:query) { 'upbeat songs from Dutch artists played on Radio 538 last week' }
  let(:translator) { described_class.new(query) }

  before do
    create(:radio_station, name: 'Radio 538')
  end

  describe '#translate' do
    subject(:translate) { translator.translate }

    context 'when the LLM returns a valid JSON response' do
      let(:llm_response) do
        {
          mood: 'upbeat',
          country: 'NL',
          radio_station: 'Radio 538',
          period: 'week'
        }.to_json
      end

      before do
        allow(translator).to receive(:chat).and_return(llm_response)
      end

      it 'returns parsed filters', :aggregate_failures do
        expect(translate[:mood]).to eq('upbeat')
        expect(translate[:country]).to eq('NL')
        expect(translate[:radio_station]).to eq('Radio 538')
        expect(translate[:period]).to eq('week')
      end
    end

    context 'when the LLM returns JSON wrapped in markdown code blocks' do
      let(:llm_response) do
        "```json\n{\"artist\": \"Drake\", \"year_from\": 2020}\n```"
      end

      before do
        allow(translator).to receive(:chat).and_return(llm_response)
      end

      it 'extracts and parses the JSON', :aggregate_failures do
        expect(translate[:artist]).to eq('Drake')
        expect(translate[:year_from]).to eq(2020)
      end
    end

    context 'when the LLM returns an empty response' do
      before do
        allow(translator).to receive(:chat).and_return(nil)
      end

      it 'returns an empty hash' do
        expect(translate).to eq({})
      end
    end

    context 'when the LLM returns invalid JSON' do
      before do
        allow(translator).to receive(:chat).and_return('not valid json at all')
      end

      it 'returns an empty hash' do
        expect(translate).to eq({})
      end
    end

    context 'when normalizing filters' do
      let(:llm_response) do
        {
          search_type: 'artists',
          mood: 'invalid_mood',
          sort_by: 'popularity',
          limit: 100,
          country: 'nl'
        }.to_json
      end

      before do
        allow(translator).to receive(:chat).and_return(llm_response)
      end

      it 'excludes unknown mood values' do
        expect(translate[:mood]).to be_nil
      end

      it 'keeps valid sort_by values' do
        expect(translate[:sort_by]).to eq('popularity')
      end

      it 'clamps limit to max 50' do
        expect(translate[:limit]).to eq(50)
      end

      it 'uppercases country codes' do
        expect(translate[:country]).to eq('NL')
      end

      it 'preserves valid search_type' do
        expect(translate[:search_type]).to eq('artists')
      end
    end
  end

  describe 'MOOD_MAPPINGS' do
    it 'contains expected moods' do
      expect(described_class::MOOD_MAPPINGS.keys).to include('upbeat', 'sad', 'chill', 'energetic', 'acoustic')
    end
  end
end
