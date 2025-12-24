# frozen_string_literal: true

describe Wikipedia::WikidataFinder do
  subject(:wikidata_finder) { described_class.new }

  describe '#get_general_info' do
    context 'when API returns valid data for a person', :use_vcr do
      let(:wikibase_item) { 'Q27982469' } # Sanne Hans / Miss Montreal

      it 'returns date of birth' do
        result = wikidata_finder.get_general_info(wikibase_item)
        expect(result['date_of_birth']).to be_present
      end

      it 'returns place of birth' do
        result = wikidata_finder.get_general_info(wikibase_item)
        expect(result['place_of_birth']).to be_present
      end

      it 'returns nationality' do
        result = wikidata_finder.get_general_info(wikibase_item)
        expect(result['nationality']).to be_present
      end

      it 'returns occupations' do
        result = wikidata_finder.get_general_info(wikibase_item)
        expect(result['occupations']).to be_present
      end
    end

    context 'when API returns valid data for a band', :use_vcr do
      let(:wikibase_item) { 'Q45188' } # Coldplay

      it 'returns genres' do
        result = wikidata_finder.get_general_info(wikibase_item)
        expect(result['genres']).to be_present
      end

      it 'returns official website' do
        result = wikidata_finder.get_general_info(wikibase_item)
        expect(result['official_website']).to be_present
      end
    end

    context 'when wikibase_item is blank' do
      it 'returns nil for nil input' do
        result = wikidata_finder.get_general_info(nil)
        expect(result).to be_nil
      end

      it 'returns nil for empty string' do
        result = wikidata_finder.get_general_info('')
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
        result = wikidata_finder.get_general_info('Q12345')
        expect(result).to be_nil
      end

      it 'logs the error' do
        wikidata_finder.get_general_info('Q12345')
        expect(Rails.logger).to have_received(:error).with(/Wikidata API error/)
      end
    end
  end

  describe '#get_official_website' do
    context 'when artist has a website', :use_vcr do
      let(:wikibase_item) { 'Q45188' } # Coldplay

      it 'returns the official website URL' do
        result = wikidata_finder.get_official_website(wikibase_item)
        expect(result).to include('coldplay')
      end
    end

    context 'when wikibase_item is blank' do
      it 'returns nil' do
        result = wikidata_finder.get_official_website(nil)
        expect(result).to be_nil
      end
    end
  end
end
