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

      it 'returns the wikibase_item' do
        result = artist_finder.get_info(artist_name)
        expect(result['wikibase_item']).to eq('Q27982469')
      end

      it 'returns the thumbnail', :aggregate_failures do
        result = artist_finder.get_info(artist_name)
        expect(result['thumbnail']).to be_present
        expect(result['thumbnail']['source']).to include('wikimedia.org')
      end

      it 'returns the original image', :aggregate_failures do
        result = artist_finder.get_info(artist_name)
        expect(result['original_image']).to be_present
        expect(result['original_image']['source']).to include('wikimedia.org')
      end

      it 'returns general_info with structured data' do
        result = artist_finder.get_info(artist_name)
        expect(result['general_info']).to be_present
      end
    end

    context 'when include_general_info is false', :use_vcr do
      let(:artist_name) { 'Miss Montreal' }

      it 'does not include general_info' do
        result = artist_finder.get_info(artist_name, include_general_info: false)
        expect(result['general_info']).to be_nil
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

  describe '#get_official_website' do
    context 'when artist has a website on Wikidata', :use_vcr do
      let(:artist_name) { 'Coldplay' }

      it 'returns the official website URL' do
        result = artist_finder.get_official_website(artist_name)
        expect(result).to include('coldplay')
      end
    end

    context 'when artist is not found', :use_vcr do
      let(:artist_name) { 'NonExistentArtistXYZ123456' }

      it 'returns nil' do
        result = artist_finder.get_official_website(artist_name)
        expect(result).to be_nil
      end
    end
  end
end
