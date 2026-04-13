# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Llm::TrackNameCleaner, type: :service do
  let(:service) { described_class.new(artist_name: artist_name, title: title) }
  let(:artist_name) { 'Dj Tiesto' }
  let(:title) { 'Red Lights - Radio 538 Versie' }

  describe '#clean' do
    subject(:clean) { service.clean }

    context 'when the LLM returns cleaned data' do
      let(:llm_response) { '{"artist": "DJ Tiësto", "title": "Red Lights"}' }

      before do
        allow(service).to receive(:chat).and_return(llm_response)
      end

      it 'returns the cleaned artist and title', :aggregate_failures do
        expect(clean['artist']).to eq('DJ Tiësto')
        expect(clean['title']).to eq('Red Lights')
      end
    end

    context 'when the LLM returns JSON wrapped in markdown code blocks' do
      let(:llm_response) { "```json\n{\"artist\": \"DJ Tiësto\", \"title\": \"Red Lights\"}\n```" }

      before do
        allow(service).to receive(:chat).and_return(llm_response)
      end

      it 'extracts and parses the JSON', :aggregate_failures do
        expect(clean['artist']).to eq('DJ Tiësto')
        expect(clean['title']).to eq('Red Lights')
      end
    end

    context 'when the LLM returns the same artist and title as input' do
      let(:llm_response) { { artist: artist_name, title: title }.to_json }

      before do
        allow(service).to receive(:chat).and_return(llm_response)
      end

      it 'returns nil to avoid duplicate searches' do
        expect(clean).to be_nil
      end
    end

    context 'when the LLM returns a response with blank artist' do
      let(:llm_response) { '{"artist": "", "title": "Red Lights"}' }

      before do
        allow(service).to receive(:chat).and_return(llm_response)
      end

      it 'returns nil' do
        expect(clean).to be_nil
      end
    end

    context 'when the LLM returns nil' do
      before do
        allow(service).to receive(:chat).and_return(nil)
      end

      it 'returns nil' do
        expect(clean).to be_nil
      end
    end

    context 'when the LLM returns invalid JSON' do
      before do
        allow(service).to receive(:chat).and_return('not valid json at all')
      end

      it 'returns nil' do
        expect(clean).to be_nil
      end
    end

    context 'when the LLM returns an array instead of a hash' do
      before do
        allow(service).to receive(:chat).and_return('[{"artist": "DJ Tiësto", "title": "Red Lights"}]')
      end

      it 'returns nil' do
        expect(clean).to be_nil
      end
    end
  end
end
