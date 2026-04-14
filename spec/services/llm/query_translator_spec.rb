# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Llm::QueryTranslator, type: :service do
  let(:query) { 'upbeat songs from Dutch artists played on Test FM last week' }
  let(:translator) { described_class.new(query) }
  let(:radio_station) { create(:radio_station) }

  before do
    radio_station
  end

  describe '#translate' do
    subject(:translate) { translator.translate }

    context 'when the LLM returns a valid JSON response' do
      let(:llm_response) do
        {
          mood: 'upbeat',
          country: 'NL',
          radio_station: radio_station.name,
          period: 'week'
        }.to_json
      end

      before do
        allow(translator).to receive(:chat).and_return(llm_response)
      end

      it 'returns parsed filters', :aggregate_failures do
        expect(translate[:mood]).to eq('upbeat')
        expect(translate[:country]).to eq('NL')
        expect(translate[:radio_station]).to eq(radio_station.name)
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

    context 'when sanitizing string filters' do
      let(:llm_response) do
        {
          artist: "Artist\x00Name\x01With\x1FControl",
          title: 'a' * 300
        }.to_json
      end

      before do
        allow(translator).to receive(:chat).and_return(llm_response)
      end

      it 'strips control characters from strings' do
        expect(translate[:artist]).to eq('ArtistNameWithControl')
      end

      it 'truncates strings exceeding max length' do
        expect(translate[:title].length).to eq(described_class::MAX_STRING_LENGTH)
      end
    end

    context 'when the LLM returns non-string filter values' do
      let(:llm_response) do
        { artist: 12_345, title: ['array'] }.to_json
      end

      before do
        allow(translator).to receive(:chat).and_return(llm_response)
      end

      it 'rejects non-string values', :aggregate_failures do
        expect(translate[:artist]).to be_nil
        expect(translate[:title]).to be_nil
      end
    end

    context 'when the LLM returns an invalid country code' do
      let(:llm_response) do
        { country: 'Netherlands' }.to_json
      end

      before do
        allow(translator).to receive(:chat).and_return(llm_response)
      end

      it 'rejects country values that are not ISO codes' do
        expect(translate[:country]).to be_nil
      end
    end

    context 'when the LLM returns a 3-letter country code' do
      let(:llm_response) do
        { country: 'nld' }.to_json
      end

      before do
        allow(translator).to receive(:chat).and_return(llm_response)
      end

      it 'accepts 3-letter ISO codes' do
        expect(translate[:country]).to eq('NLD')
      end
    end

    context 'when the query contains lyrics' do
      let(:llm_response) do
        {
          artist: 'Adele',
          title: 'Hello',
          lyrics: 'Hello from the other side',
          period: 'all'
        }.to_json
      end

      before do
        allow(translator).to receive(:chat).and_return(llm_response)
      end

      it 'returns artist, title, and lyrics filters', :aggregate_failures do
        expect(translate[:artist]).to eq('Adele')
        expect(translate[:title]).to eq('Hello')
        expect(translate[:lyrics]).to eq('Hello from the other side')
      end
    end

    context 'when the query asks for a limited number of results' do
      let(:llm_response) do
        {
          radio_station: radio_station.name,
          period: 'month',
          sort_by: 'most_played',
          limit: 3
        }.to_json
      end

      before do
        allow(translator).to receive(:chat).and_return(llm_response)
      end

      it 'returns the limit filter', :aggregate_failures do
        expect(translate[:limit]).to eq(3)
        expect(translate[:sort_by]).to eq('most_played')
      end
    end
  end

  describe 'MOOD_MAPPINGS' do
    it 'contains expected moods' do
      expect(described_class::MOOD_MAPPINGS.keys).to include('upbeat', 'sad', 'chill', 'energetic', 'acoustic')
    end
  end
end
