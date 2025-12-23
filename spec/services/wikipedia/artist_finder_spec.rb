# frozen_string_literal: true

describe Wikipedia::ArtistFinder do
  subject(:artist_finder) { described_class.new }

  describe '#get_info' do
    let(:artist_name) { 'Coldplay' }

    context 'when API returns valid data' do
      let(:api_response) do
        {
          'type' => 'standard',
          'title' => 'Coldplay',
          'extract_html' => '<p><b>Coldplay</b> are a British rock band formed in London in 1997.</p>',
          'description' => 'British rock band',
          'content_urls' => {
            'desktop' => {
              'page' => 'https://en.wikipedia.org/wiki/Coldplay'
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

      it 'returns the bio data with summary, description and url' do
        result = artist_finder.get_info(artist_name)
        expect(result).to eq({
                               'summary' => '<p><b>Coldplay</b> are a British rock band formed in London in 1997.</p>',
                               'description' => 'British rock band',
                               'url' => 'https://en.wikipedia.org/wiki/Coldplay'
                             })
      end
    end

    context 'when API returns not found' do
      let(:not_found_response) do
        {
          'type' => 'not_found',
          'title' => 'Not found'
        }
      end

      before do
        allow(Rails.cache).to receive(:fetch).and_yield
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return( # rubocop:disable RSpec/AnyInstance
          instance_double(Faraday::Response, body: not_found_response)
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
        expect(Rails.logger).to have_received(:error).with(/Wikipedia API error/)
      end
    end
  end
end
