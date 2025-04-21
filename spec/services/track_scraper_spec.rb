# frozen_string_literal: true

require 'rails_helper'

describe TrackScraper, type: :service do
  let(:radio_station) { double('RadioStation', name: 'Test Station', url: 'http://example.com/api') }
  let(:track_scraper) { described_class.new(radio_station) }

  describe '#make_request' do
    subject(:make_request) { track_scraper.send(:make_request) }

    context 'when the request is successful' do
      let(:response_body) { { data: { song: { artist: 'Test Artist', title: 'Test Title' } } } }
      let(:response) { instance_double(Faraday::Response, success?: true, body: response_body) }

      before do
        allow(Faraday).to receive(:new).and_return(double(get: response))
      end

      it 'returns the parsed response body' do
        expect(make_request).to eq(response_body.with_indifferent_access)
      end
    end

    context 'when the request fails' do
      let(:response) { instance_double(Faraday::Response, success?: false, status: 500) }

      before do
        allow(Faraday).to receive(:new).and_return(double(get: response))
        allow(Rails.logger).to receive(:error)
      end

      it 'returns an empty array' do
        expect(make_request).to eq([])
      end

      it 'logs an error and returns an empty array' do
        make_request
        expect(Rails.logger).to have_received(:error).with('Error fetching data from Test Station: 500')
      end
    end
  end
end
