# frozen_string_literal: true

describe SongImporter::ScraperImporter do
  let(:radio_station) { create(:radio_station) }
  let(:artist) { create(:artist, name: 'Test Artist') }
  let(:song) { create(:song, title: 'Test Song', artists: [artist]) }
  let(:other_song) { create(:song, title: 'Other Song', artists: [artist]) }

  subject(:scraper_importer) do
    described_class.new(radio_station: radio_station, artists: [artist], song: song)
  end

  describe '#last_added_scraper_song' do
    context 'when no scraper imports exist' do
      it 'returns nil' do
        expect(scraper_importer.send(:last_added_scraper_song)).to be_nil
      end
    end

    context 'when scraper imports exist' do
      let!(:scraper_air_play) do
        create(:air_play,
               radio_station: radio_station,
               song: other_song,
               scraper_import: true,
               broadcasted_at: 30.minutes.ago)
      end

      it 'returns the song from the most recent scraper import' do
        expect(scraper_importer.send(:last_added_scraper_song)).to eq(other_song)
      end
    end

    context 'when multiple scraper imports exist' do
      let!(:older_scraper_air_play) do
        create(:air_play,
               radio_station: radio_station,
               song: other_song,
               scraper_import: true,
               broadcasted_at: 2.hours.ago,
               created_at: 2.hours.ago)
      end
      let!(:newer_scraper_air_play) do
        create(:air_play,
               radio_station: radio_station,
               song: song,
               scraper_import: true,
               broadcasted_at: 30.minutes.ago,
               created_at: 30.minutes.ago)
      end

      it 'returns the most recent scraper import song' do
        expect(scraper_importer.send(:last_added_scraper_song)).to eq(song)
      end
    end

    context 'when only recognizer imports exist (no scraper imports)' do
      let!(:recognizer_air_play) do
        create(:air_play,
               radio_station: radio_station,
               song: other_song,
               scraper_import: false,
               broadcasted_at: 30.minutes.ago)
      end

      it 'returns nil' do
        expect(scraper_importer.send(:last_added_scraper_song)).to be_nil
      end
    end

    context 'when scraper imports exist for different radio station' do
      let(:other_radio_station) { create(:radio_station) }
      let!(:other_station_air_play) do
        create(:air_play,
               radio_station: other_radio_station,
               song: other_song,
               scraper_import: true,
               broadcasted_at: 30.minutes.ago)
      end

      it 'returns nil for original radio station' do
        expect(scraper_importer.send(:last_added_scraper_song)).to be_nil
      end
    end
  end

  describe '#not_last_added_song' do
    context 'when song is the same as last added scraper song' do
      let!(:scraper_air_play) do
        create(:air_play,
               radio_station: radio_station,
               song: song,
               scraper_import: true,
               broadcasted_at: 30.minutes.ago)
      end

      it 'returns true (same song is allowed for scraper imports)' do
        # Note: ScraperImporter uses == comparison, which is inverted from RecognizerImporter
        expect(scraper_importer.send(:not_last_added_song)).to be true
      end
    end

    context 'when song is different from last added scraper song' do
      let!(:scraper_air_play) do
        create(:air_play,
               radio_station: radio_station,
               song: other_song,
               scraper_import: true,
               broadcasted_at: 30.minutes.ago)
      end

      it 'returns false' do
        expect(scraper_importer.send(:not_last_added_song)).to be false
      end
    end

    context 'when no scraper imports exist' do
      it 'returns false (nil != song)' do
        expect(scraper_importer.send(:not_last_added_song)).to be false
      end
    end
  end

  describe '#may_import_song?' do
    context 'when song is the last added scraper song' do
      let!(:scraper_air_play) do
        create(:air_play,
               radio_station: radio_station,
               song: song,
               scraper_import: true,
               broadcasted_at: 30.minutes.ago,
               created_at: 30.minutes.ago)
      end

      it 'returns false because same song was played recently (matches exist)' do
        # not_last_added_song returns true (song == last_added_scraper_song)
        # but any_song_matches? also returns true because the same song was played
        # so may_import_song? = true && !true = false
        expect(scraper_importer.may_import_song?).to be false
      end
    end

    context 'when song is different from last added scraper song' do
      let!(:scraper_air_play) do
        create(:air_play,
               radio_station: radio_station,
               song: other_song,
               scraper_import: true,
               broadcasted_at: 30.minutes.ago,
               created_at: 30.minutes.ago)
      end

      it 'returns false because not_last_added_song is false' do
        # not_last_added_song returns false (song != last_added_scraper_song)
        expect(scraper_importer.may_import_song?).to be false
      end
    end

    context 'when song is the last added and played more than 1 hour ago' do
      let!(:scraper_air_play) do
        create(:air_play,
               radio_station: radio_station,
               song: song,
               scraper_import: true,
               broadcasted_at: 2.hours.ago,
               created_at: 2.hours.ago)
      end

      it 'returns true because not_last_added_song is true and no recent matches' do
        # not_last_added_song returns true (song == last_added_scraper_song)
        # any_song_matches? returns false because no songs played in last hour
        # so may_import_song? = true && !false = true
        expect(scraper_importer.may_import_song?).to be true
      end
    end
  end

  describe 'memoization of last_added_scraper_song' do
    context 'when called multiple times' do
      let!(:scraper_air_play) do
        create(:air_play,
               radio_station: radio_station,
               song: other_song,
               scraper_import: true,
               broadcasted_at: 30.minutes.ago)
      end

      it 'returns consistent results' do
        first_call = scraper_importer.send(:last_added_scraper_song)
        second_call = scraper_importer.send(:last_added_scraper_song)
        expect(first_call).to eq(second_call)
      end
    end
  end
end
