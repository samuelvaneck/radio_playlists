# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wikipedia::WikidataTimelineFinder, type: :service do
  subject(:finder) { described_class.new }

  let(:wikibase_item) { 'Q4936' }

  before do
    allow(Rails.cache).to receive(:fetch).and_yield
  end

  describe '#call' do
    context 'when wikibase_item is blank' do
      it 'returns an empty array for nil' do
        expect(finder.(nil)).to eq([])
      end

      it 'returns an empty array for an empty string' do
        expect(finder.('')).to eq([])
      end
    end

    context 'when SPARQL endpoint returns a non-JSON body' do
      let(:sparql_response) { instance_double(Faraday::Response, body: '<html>Service Unavailable</html>', status: 503) }
      let(:entity_response) { instance_double(Faraday::Response, body: '<html>Service Unavailable</html>', status: 503) }
      let(:sparql_connection) { instance_double(Faraday::Connection) }
      let(:entity_connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).with(hash_including(url: described_class::SPARQL_URL)).and_return(sparql_connection)
        allow(Faraday).to receive(:new).with(hash_including(url: described_class::ENTITY_API_URL)).and_return(entity_connection)
        allow(sparql_connection).to receive(:get).and_yield(double(params: {})).and_return(sparql_response)
        allow(entity_connection).to receive(:get).and_return(entity_response)
        allow(Rails.logger).to receive(:warn)
      end

      it 'returns an empty array instead of raising NoMethodError' do
        expect { finder.(wikibase_item) }.not_to raise_error
      end

      it 'falls back to an empty array' do
        expect(finder.(wikibase_item)).to eq([])
      end

      it 'logs a warning about the non-JSON response' do
        finder.(wikibase_item)
        expect(Rails.logger).to have_received(:warn).with(/Wikidata returned non-JSON response/).at_least(:once)
      end
    end

    context 'when SPARQL endpoint returns valid JSON' do
      let(:sparql_body) do
        {
          'results' => {
            'bindings' => [
              {
                'category' => { 'value' => 'formation' },
                'date' => { 'value' => '+1993-01-01T00:00:00Z' },
                'subjectLabel' => { 'value' => 'Daft Punk formed' }
              }
            ]
          }
        }
      end
      let(:sparql_response) { instance_double(Faraday::Response, body: sparql_body, status: 200) }
      let(:sparql_connection) { instance_double(Faraday::Connection) }
      let(:entity_connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).with(hash_including(url: described_class::SPARQL_URL)).and_return(sparql_connection)
        allow(Faraday).to receive(:new).with(hash_including(url: described_class::ENTITY_API_URL)).and_return(entity_connection)
        allow(sparql_connection).to receive(:get).and_yield(double(params: {})).and_return(sparql_response)
      end

      it 'returns the mapped events' do
        result = finder.(wikibase_item)
        expect(result.first).to include('category' => 'formation', 'source' => 'wikidata')
      end
    end
  end
end
