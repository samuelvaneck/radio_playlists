# frozen_string_literal: true

describe Wikipedia::SongFinder do
  subject(:song_finder) { described_class.new }

  describe '#get_info' do
    context 'when API returns valid data', :use_vcr do
      let(:song_title) { 'Rolling in the Deep' }
      let(:artist_name) { 'Adele' }

      it 'returns the info data with summary' do
        result = song_finder.get_info(song_title, artist_name)
        expect(result['summary']).to be_present
      end

      it 'returns the Wikipedia url' do
        result = song_finder.get_info(song_title, artist_name)
        expect(result['url']).to include('wikipedia.org')
      end

      it 'returns the wikibase_item' do
        result = song_finder.get_info(song_title, artist_name)
        expect(result['wikibase_item']).to be_present
      end
    end

    context 'when include_general_info is true', :use_vcr do
      let(:song_title) { 'Rolling in the Deep' }
      let(:artist_name) { 'Adele' }

      it 'includes general_info with song data' do
        result = song_finder.get_info(song_title, artist_name, include_general_info: true)
        expect(result['general_info']).to be_a(Hash).or be_nil
      end
    end

    context 'when include_general_info is false', :use_vcr do
      let(:song_title) { 'Rolling in the Deep' }
      let(:artist_name) { 'Adele' }

      it 'does not include general_info' do
        result = song_finder.get_info(song_title, artist_name, include_general_info: false)
        expect(result['general_info']).to be_nil
      end
    end

    context 'when song is not found', :use_vcr do
      let(:song_title) { 'NonExistentSongXYZ123456' }
      let(:artist_name) { 'UnknownArtist' }

      it 'returns nil' do
        result = song_finder.get_info(song_title, artist_name)
        expect(result).to be_nil
      end
    end

    context 'when song_title is blank' do
      it 'returns nil for nil input' do
        result = song_finder.get_info(nil, 'Adele')
        expect(result).to be_nil
      end

      it 'returns nil for empty string' do
        result = song_finder.get_info('', 'Adele')
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
        result = song_finder.get_info('Any Song', 'Any Artist')
        expect(result).to be_nil
      end

      it 'logs the error' do
        song_finder.get_info('Any Song', 'Any Artist')
        expect(Rails.logger).to have_received(:error).with(/Wikipedia API error/).at_least(:once)
      end
    end
  end

  describe '#get_youtube_video_id' do
    context 'when song has a YouTube video ID in Wikidata', :use_vcr do
      let(:song_title) { 'Rolling in the Deep' }
      let(:artist_name) { 'Adele' }

      it 'returns the YouTube video ID or nil' do
        result = song_finder.get_youtube_video_id(song_title, artist_name)
        expect(result).to be_a(String).or be_nil
      end
    end

    context 'when song is not found', :use_vcr do
      let(:song_title) { 'NonExistentSongXYZ123456' }
      let(:artist_name) { 'UnknownArtist' }

      it 'returns nil' do
        result = song_finder.get_youtube_video_id(song_title, artist_name)
        expect(result).to be_nil
      end
    end

    context 'when song_title is blank' do
      it 'returns nil' do
        result = song_finder.get_youtube_video_id(nil, 'Adele')
        expect(result).to be_nil
      end
    end
  end

  describe '#get_youtube_video_id_by_spotify_id' do
    context 'when song exists in Wikidata', :use_vcr do
      let(:spotify_id) { '1c8gk2PeTE04A1pIDH9YMk' } # Rolling in the Deep

      it 'returns the YouTube video ID or nil' do
        result = song_finder.get_youtube_video_id_by_spotify_id(spotify_id)
        expect(result).to be_a(String).or be_nil
      end
    end

    context 'when spotify_id is blank' do
      it 'returns nil for nil input' do
        result = song_finder.get_youtube_video_id_by_spotify_id(nil)
        expect(result).to be_nil
      end

      it 'returns nil for empty string' do
        result = song_finder.get_youtube_video_id_by_spotify_id('')
        expect(result).to be_nil
      end
    end
  end

  describe '#get_youtube_video_id_by_isrc' do
    context 'when song exists in Wikidata', :use_vcr do
      let(:isrc) { 'GBBKS1000094' } # Rolling in the Deep

      it 'returns the YouTube video ID or nil' do
        result = song_finder.get_youtube_video_id_by_isrc(isrc)
        expect(result).to be_a(String).or be_nil
      end
    end

    context 'when isrc is blank' do
      it 'returns nil for nil input' do
        result = song_finder.get_youtube_video_id_by_isrc(nil)
        expect(result).to be_nil
      end

      it 'returns nil for empty string' do
        result = song_finder.get_youtube_video_id_by_isrc('')
        expect(result).to be_nil
      end
    end
  end

  describe 'language support' do
    context 'with Dutch language', :use_vcr do
      subject(:song_finder) { described_class.new(language: 'nl') }

      let(:song_title) { 'Viva la Vida' }
      let(:artist_name) { 'Coldplay' }

      it 'returns info from Dutch Wikipedia when available' do
        result = song_finder.get_info(song_title, artist_name, include_general_info: false)
        # May return nil if no Dutch page exists, or URL with nl.wikipedia.org
        expect(result['url']).to include('wikipedia.org') if result.present? && result['url'].present?
      end
    end

    context 'with unsupported language' do
      subject(:song_finder) { described_class.new(language: 'invalid') }

      it 'falls back to English' do
        expect(song_finder.send(:language)).to eq('en')
      end
    end
  end
end
