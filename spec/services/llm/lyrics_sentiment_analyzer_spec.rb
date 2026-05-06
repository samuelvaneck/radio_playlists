# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Llm::LyricsSentimentAnalyzer, type: :service do
  let(:service) { described_class.new(lyrics: lyrics) }
  let(:lyrics) { "I've been tryna call\nI've been on my own for long enough\n" }

  describe '#analyze' do
    subject(:analyze) { service.analyze }

    context 'when the LLM returns a valid sentiment hash' do
      let(:llm_response) do
        '{"sentiment": -0.3, "themes": ["loneliness", "love"], "language": "en", "confidence": 0.82}'
      end

      before { allow(service).to receive(:chat).and_return(llm_response) }

      it 'returns a parsed sentiment hash', :aggregate_failures do
        expect(analyze[:sentiment]).to eq(-0.3)
        expect(analyze[:themes]).to eq(%w[loneliness love])
        expect(analyze[:language]).to eq('en')
        expect(analyze[:confidence]).to eq(0.82)
      end
    end

    context 'when sentiment is out of range' do
      let(:llm_response) { '{"sentiment": 2.5, "themes": [], "language": "en", "confidence": 1.5}' }

      before { allow(service).to receive(:chat).and_return(llm_response) }

      it 'clamps to [-1, 1] and confidence to [0, 1]', :aggregate_failures do
        expect(analyze[:sentiment]).to eq(1.0)
        expect(analyze[:confidence]).to eq(1.0)
      end
    end

    context 'when sentiment is null (unanalyzable lyrics)' do
      let(:llm_response) { '{"sentiment": null, "themes": [], "language": null, "confidence": 0.0}' }

      before { allow(service).to receive(:chat).and_return(llm_response) }

      it 'returns a hash with nil sentiment', :aggregate_failures do
        expect(analyze[:sentiment]).to be_nil
        expect(analyze[:themes]).to eq([])
      end
    end

    context 'when themes contains duplicates and blank values' do
      let(:llm_response) { '{"sentiment": 0, "themes": ["Love", "love", "", "hope"], "language": "en", "confidence": 0.5}' }

      before { allow(service).to receive(:chat).and_return(llm_response) }

      it 'normalizes, dedupes, and caps to 5 themes' do
        expect(analyze[:themes]).to eq(%w[love hope])
      end
    end

    context 'when LLM wraps response in markdown' do
      let(:llm_response) { "```json\n{\"sentiment\": 0.4, \"themes\": [\"hope\"], \"language\": \"nl\", \"confidence\": 0.7}\n```" }

      before { allow(service).to receive(:chat).and_return(llm_response) }

      it 'extracts the JSON' do
        expect(analyze[:sentiment]).to eq(0.4)
      end
    end

    context 'when lyrics are blank' do
      let(:lyrics) { '' }

      before { allow(service).to receive(:chat) }

      it 'returns nil without calling the LLM', :aggregate_failures do
        expect(analyze).to be_nil
        expect(service).not_to have_received(:chat)
      end
    end

    context 'when the LLM returns invalid JSON' do
      before { allow(service).to receive(:chat).and_return('not json') }

      it 'returns nil' do
        expect(analyze).to be_nil
      end
    end

    context 'when the LLM returns nil' do
      before { allow(service).to receive(:chat).and_return(nil) }

      it 'returns nil' do
        expect(analyze).to be_nil
      end
    end
  end
end
