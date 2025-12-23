# frozen_string_literal: true

describe Wikipedia::ArtistFinder do
  subject(:artist_finder) { described_class.new }

  describe '#get_info' do
    context 'when API returns valid data', :use_vcr do
      let(:artist_name) { 'Miss Montreal' }

      it 'returns the bio data with summary' do
        result = artist_finder.get_info(artist_name)
        expect(result['summary']).to include('Dutch singer')
      end

      it 'returns the full content' do
        result = artist_finder.get_info(artist_name)
        expect(result['content']).to include('Miss Montreal')
      end

      it 'returns the description' do
        result = artist_finder.get_info(artist_name)
        expect(result['description']).to eq('Dutch singer')
      end

      it 'returns the Wikipedia url' do
        result = artist_finder.get_info(artist_name)
        expect(result['url']).to eq('https://en.wikipedia.org/wiki/Sanne_Hans')
      end
    end

    context 'when API returns not found', :use_vcr do
      let(:artist_name) { 'NonExistentArtistXYZ123456' }

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
        result = artist_finder.get_info('Any Artist')
        expect(result).to be_nil
      end

      it 'logs the error' do
        artist_finder.get_info('Any Artist')
        expect(Rails.logger).to have_received(:error).with(/Wikipedia API error/)
      end
    end
  end
end
