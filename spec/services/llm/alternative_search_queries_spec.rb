# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Llm::AlternativeSearchQueries, type: :service do
  let(:service) { described_class.new(artist_name: artist_name, title: title) }
  let(:artist_name) { 'Dj Tiesto' }
  let(:title) { 'Red Lights (Radio 538 Versie)' }

  describe '#generate' do
    subject(:generate) { service.generate }

    context 'when the LLM returns valid alternative queries' do
      let(:llm_response) do
        [
          { artist: 'Tiësto', title: 'Red Lights' },
          { artist: 'DJ Tiësto', title: 'Red Lights' }
        ].to_json
      end

      before do
        allow(service).to receive(:chat).and_return(llm_response)
      end

      it 'returns parsed query alternatives', :aggregate_failures do
        expect(generate.length).to eq(2)
        expect(generate.first['artist']).to eq('Tiësto')
        expect(generate.first['title']).to eq('Red Lights')
      end
    end

    context 'when the LLM returns JSON wrapped in markdown code blocks' do
      let(:llm_response) do
        "```json\n[{\"artist\": \"Tiësto\", \"title\": \"Red Lights\"}]\n```"
      end

      before do
        allow(service).to receive(:chat).and_return(llm_response)
      end

      it 'extracts and parses the JSON' do
        expect(generate.length).to eq(1)
      end
    end

    context 'when the LLM returns more than MAX_QUERIES results' do
      let(:llm_response) do
        [
          { artist: 'A', title: 'T1' },
          { artist: 'B', title: 'T2' },
          { artist: 'C', title: 'T3' },
          { artist: 'D', title: 'T4' }
        ].to_json
      end

      before do
        allow(service).to receive(:chat).and_return(llm_response)
      end

      it 'limits results to MAX_QUERIES' do
        expect(generate.length).to eq(3)
      end
    end

    context 'when the LLM returns entries with blank fields' do
      let(:llm_response) do
        [
          { artist: '', title: 'Red Lights' },
          { artist: 'Tiësto', title: '' },
          { artist: 'Tiësto', title: 'Red Lights' }
        ].to_json
      end

      before do
        allow(service).to receive(:chat).and_return(llm_response)
      end

      it 'filters out entries with blank artist or title', :aggregate_failures do
        expect(generate.length).to eq(1)
        expect(generate.first['artist']).to eq('Tiësto')
      end
    end

    context 'when the LLM returns nil' do
      before do
        allow(service).to receive(:chat).and_return(nil)
      end

      it 'returns an empty array' do
        expect(generate).to eq([])
      end
    end

    context 'when the LLM returns invalid JSON' do
      before do
        allow(service).to receive(:chat).and_return('not valid json')
      end

      it 'returns an empty array' do
        expect(generate).to eq([])
      end
    end

    context 'when the LLM returns a hash instead of an array' do
      before do
        allow(service).to receive(:chat).and_return('{"artist": "Tiësto", "title": "Red Lights"}')
      end

      it 'returns an empty array' do
        expect(generate).to eq([])
      end
    end
  end
end
