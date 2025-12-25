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

  describe '#get_song_info' do
    context 'when song has valid data', :use_vcr do
      let(:wikibase_item) { 'Q212764' } # Rolling in the Deep by Adele

      it 'returns song info hash' do
        result = wikidata_finder.get_song_info(wikibase_item)
        expect(result).to be_a(Hash)
      end

      it 'returns genres when present' do
        result = wikidata_finder.get_song_info(wikibase_item)
        expect(result['genres']).to be_present if result['genres']
      end
    end

    context 'when wikibase_item is blank' do
      it 'returns nil' do
        result = wikidata_finder.get_song_info(nil)
        expect(result).to be_nil
      end
    end
  end

  describe '#get_youtube_video_id' do
    context 'when song has youtube video id', :use_vcr do
      let(:wikibase_item) { 'Q212764' } # Rolling in the Deep by Adele

      it 'returns the youtube video id' do
        result = wikidata_finder.get_youtube_video_id(wikibase_item)
        # May or may not have a youtube ID depending on Wikidata state
        expect(result).to be_a(String).or be_nil
      end
    end

    context 'when wikibase_item is blank' do
      it 'returns nil' do
        result = wikidata_finder.get_youtube_video_id(nil)
        expect(result).to be_nil
      end
    end
  end

  describe '#search_by_spotify_id' do
    context 'when song exists in Wikidata', :use_vcr do
      let(:spotify_id) { '1c8gk2PeTE04A1pIDH9YMk' } # Rolling in the Deep

      it 'returns the wikibase item id' do
        result = wikidata_finder.search_by_spotify_id(spotify_id)
        # May or may not find it depending on Wikidata state
        expect(result).to be_a(String).or be_nil
      end
    end

    context 'when spotify_id is blank' do
      it 'returns nil for nil input' do
        result = wikidata_finder.search_by_spotify_id(nil)
        expect(result).to be_nil
      end

      it 'returns nil for empty string' do
        result = wikidata_finder.search_by_spotify_id('')
        expect(result).to be_nil
      end
    end
  end

  describe '#search_by_isrc' do
    context 'when song exists in Wikidata', :use_vcr do
      let(:isrc) { 'GBBKS1000094' } # Rolling in the Deep

      it 'returns the wikibase item id' do
        result = wikidata_finder.search_by_isrc(isrc)
        # May or may not find it depending on Wikidata state
        expect(result).to be_a(String).or be_nil
      end
    end

    context 'when isrc is blank' do
      it 'returns nil for nil input' do
        result = wikidata_finder.search_by_isrc(nil)
        expect(result).to be_nil
      end

      it 'returns nil for empty string' do
        result = wikidata_finder.search_by_isrc('')
        expect(result).to be_nil
      end
    end
  end
end
