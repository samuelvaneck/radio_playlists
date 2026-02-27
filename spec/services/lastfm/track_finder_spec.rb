# frozen_string_literal: true

require 'rails_helper'

describe Lastfm::TrackFinder do
  subject(:track_finder) { described_class.new }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('LASTFM_API_KEY', nil).and_return('test_api_key')
  end

  describe '#get_info' do
    let(:artist_name) { 'Coldplay' }
    let(:track_name) { 'Yellow' }

    context 'when API returns valid data' do
      let(:api_response) do
        {
          'track' => {
            'name' => 'Yellow',
            'artist' => { 'name' => 'Coldplay' },
            'listeners' => '3000000',
            'playcount' => '50000000',
            'toptags' => { 'tag' => [{ 'name' => 'rock' }, { 'name' => 'alternative' }] }
          }
        }
      end

      before do
        allow(Rails.cache).to receive(:fetch).and_yield
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return( # rubocop:disable RSpec/AnyInstance
          instance_double(Faraday::Response, body: api_response, status: 200)
        )
      end

      it 'returns the track data' do
        result = track_finder.get_info(artist_name: artist_name, track_name: track_name)
        expect(result).to eq(api_response['track'])
      end
    end

    context 'when API returns an error' do
      let(:error_response) { { 'error' => 6, 'message' => 'Track not found' } }

      before do
        allow(Rails.cache).to receive(:fetch).and_yield
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return( # rubocop:disable RSpec/AnyInstance
          instance_double(Faraday::Response, body: error_response, status: 200)
        )
      end

      it 'returns nil' do
        expect(track_finder.get_info(artist_name: artist_name, track_name: track_name)).to be_nil
      end
    end

    context 'when API request fails' do
      before do
        allow(Rails.cache).to receive(:fetch).and_yield
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_raise(Faraday::Error) # rubocop:disable RSpec/AnyInstance
        allow(ExceptionNotifier).to receive(:notify)
        allow(Rails.logger).to receive(:error)
      end

      it 'returns nil' do
        expect(track_finder.get_info(artist_name: artist_name, track_name: track_name)).to be_nil
      end
    end
  end

  describe '#get_top_tags' do
    let(:artist_name) { 'Coldplay' }
    let(:track_name) { 'Yellow' }

    context 'when API returns valid data' do
      let(:api_response) do
        {
          'toptags' => {
            'tag' => [
              { 'name' => 'rock', 'count' => 100 },
              { 'name' => 'britpop', 'count' => 80 }
            ]
          }
        }
      end

      before do
        allow(Rails.cache).to receive(:fetch).and_yield
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return( # rubocop:disable RSpec/AnyInstance
          instance_double(Faraday::Response, body: api_response, status: 200)
        )
      end

      it 'returns the tags array' do
        result = track_finder.get_top_tags(artist_name: artist_name, track_name: track_name)
        expect(result).to eq(api_response['toptags']['tag'])
      end
    end

    context 'when API returns an error' do
      let(:error_response) { { 'error' => 6, 'message' => 'Track not found' } }

      before do
        allow(Rails.cache).to receive(:fetch).and_yield
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return( # rubocop:disable RSpec/AnyInstance
          instance_double(Faraday::Response, body: error_response, status: 200)
        )
      end

      it 'returns nil' do
        expect(track_finder.get_top_tags(artist_name: artist_name, track_name: track_name)).to be_nil
      end
    end
  end
end
