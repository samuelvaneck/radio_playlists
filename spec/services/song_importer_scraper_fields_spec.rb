# frozen_string_literal: true

describe SongImporter do
  describe '#persist_scraper_fields' do
    subject(:persist) { importer.send(:persist_scraper_fields) }

    let(:radio_station) { create(:radio_station, processor: 'qmusic_api_processor') }
    let(:artist)        { create(:artist, name: 'Ed Sheeran', website_url: nil, instagram_url: nil) }
    let(:song)          { create(:song, title: 'Sapphire', artists: [artist], id_on_youtube: nil) }
    let(:importer)      { described_class.new(radio_station: radio_station) }

    let(:scraper) do
      instance_double(
        TrackScraper::QmusicApiProcessor,
        artist_name: 'Ed Sheeran',
        youtube_id: 'JgDNFQ2RaLQ',
        website_url: 'http://edsheeran.com/',
        instagram_url: 'https://instagram.com/teddysphotos'
      )
    end

    before do
      importer.instance_variable_set(:@played_song, scraper)
      importer.instance_variable_set(:@song, song)
    end

    it 'updates the song id_on_youtube from the scraper' do
      persist

      expect(song.reload.id_on_youtube).to eq('JgDNFQ2RaLQ')
    end

    it 'updates the matching artist website_url and instagram_url', :aggregate_failures do
      persist
      artist.reload

      expect(artist.website_url).to eq('http://edsheeran.com/')
      expect(artist.instagram_url).to eq('https://instagram.com/teddysphotos')
    end

    context 'when the played_song is a recognizer, not a scraper' do
      let(:recognizer) { instance_double(SongRecognizer) }

      before { importer.instance_variable_set(:@played_song, recognizer) }

      it 'does not touch the song' do
        expect { persist }.not_to(change { song.reload.id_on_youtube })
      end
    end

    context 'when the song already has a youtube id' do
      let(:song) { create(:song, title: 'Sapphire', artists: [artist], id_on_youtube: 'pre-existing') }

      it 'does not overwrite the existing id_on_youtube' do
        expect { persist }.not_to(change { song.reload.id_on_youtube })
      end
    end

    context 'when the artist already has a website_url' do
      let(:artist) { create(:artist, name: 'Ed Sheeran', website_url: 'http://existing.example/', instagram_url: nil) }

      it 'does not overwrite the existing website_url' do
        expect { persist }.not_to(change { artist.reload.website_url })
      end
    end

    context 'when the scraper does not provide the fields' do
      let(:scraper) do
        instance_double(
          TrackScraper::QmusicApiProcessor,
          artist_name: 'Ed Sheeran', youtube_id: nil, website_url: nil, instagram_url: nil
        )
      end

      it 'leaves the song id_on_youtube unchanged' do
        expect { persist }.not_to(change { song.reload.id_on_youtube })
      end
    end

    context 'when no song artist matches the scraped artist name' do
      let(:scraper) do
        instance_double(
          TrackScraper::QmusicApiProcessor,
          artist_name: 'Different Artist',
          youtube_id: 'JgDNFQ2RaLQ',
          website_url: 'http://different.example/',
          instagram_url: nil
        )
      end

      it 'still updates the song id_on_youtube but skips the artist update', :aggregate_failures do
        persist
        artist.reload

        expect(song.reload.id_on_youtube).to eq('JgDNFQ2RaLQ')
        expect(artist.website_url).to be_nil
      end
    end
  end
end
