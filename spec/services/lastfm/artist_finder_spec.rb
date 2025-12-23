# frozen_string_literal: true

describe Lastfm::ArtistFinder do
  subject(:artist_finder) { described_class.new }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('LASTFM_API_KEY', nil).and_return('test_api_key')
  end

  describe '#get_info' do
    let(:artist_name) { 'Coldplay' }

    context 'when API returns valid data' do
      let(:api_response) do
        {
          'artist' => {
            'name' => 'Coldplay',
            'bio' => {
              'summary' => 'Coldplay are a British rock band formed in London in 1996.',
              'content' => 'Full biography content here.'
            }
          }
        }
      end

      before do
        allow(Rails.cache).to receive(:fetch).and_yield
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return( # rubocop:disable RSpec/AnyInstance
          instance_double(Faraday::Response, body: api_response)
        )
      end

      it 'returns the bio data' do
        result = artist_finder.get_info(artist_name)
        expect(result).to eq(api_response['artist']['bio'])
      end
    end

    context 'when API returns an error' do
      let(:error_response) do
        {
          'error' => 6,
          'message' => 'Artist not found'
        }
      end

      before do
        allow(Rails.cache).to receive(:fetch).and_yield
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return( # rubocop:disable RSpec/AnyInstance
          instance_double(Faraday::Response, body: error_response)
        )
      end

      it 'returns nil' do
        result = artist_finder.get_info(artist_name)
        expect(result).to be_nil
      end
    end

    context 'when API request fails' do
      before do
        allow(Rails.cache).to receive(:fetch).and_yield
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_raise(Faraday::Error) # rubocop:disable RSpec/AnyInstance
        allow(ExceptionNotifier).to receive(:notify_new_relic)
        allow(Rails.logger).to receive(:error)
      end

      it 'returns nil' do
        result = artist_finder.get_info(artist_name)
        expect(result).to be_nil
      end

      it 'logs the error' do
        artist_finder.get_info(artist_name)
        expect(Rails.logger).to have_received(:error).with(/Lastfm API error/)
      end
    end
  end
end
