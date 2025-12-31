# frozen_string_literal: true

describe SongImporter::ScraperImporter do
  subject(:scraper_importer) do
    described_class.new(radio_station: radio_station, artists: [artist], song: song)
  end

  let(:radio_station) { create(:radio_station) }
  let(:artist) { create(:artist, name: 'Test Artist') }
  let(:song) { create(:song, title: 'Test Song', artists: [artist]) }
  let(:other_song) { create(:song, title: 'Other Song', artists: [artist]) }

  describe '#last_added_scraper_song' do
    context 'when no scraper imports exist' do
      it 'returns nil' do
        expect(scraper_importer.send(:last_added_scraper_song)).to be_nil
      end
    end

    context 'when scraper imports exist' do
      before do
        create(:air_play, radio_station: radio_station, song: other_song,
                          scraper_import: true, broadcasted_at: 30.minutes.ago)
      end

      it 'returns the song from the most recent scraper import' do
        expect(scraper_importer.send(:last_added_scraper_song)).to eq(other_song)
      end
    end

    context 'when multiple scraper imports exist' do
      before do
        create(:air_play, radio_station: radio_station, song: other_song,
                          scraper_import: true, broadcasted_at: 2.hours.ago, created_at: 2.hours.ago)
        create(:air_play, radio_station: radio_station, song: song,
                          scraper_import: true, broadcasted_at: 30.minutes.ago, created_at: 30.minutes.ago)
      end

      it 'returns the most recent scraper import song' do
        expect(scraper_importer.send(:last_added_scraper_song)).to eq(song)
      end
    end

    context 'when only recognizer imports exist (no scraper imports)' do
      before do
        create(:air_play, radio_station: radio_station, song: other_song,
                          scraper_import: false, broadcasted_at: 30.minutes.ago)
      end

      it 'returns nil' do
        expect(scraper_importer.send(:last_added_scraper_song)).to be_nil
      end
    end

    context 'when scraper imports exist for different radio station' do
      let(:other_radio_station) { create(:radio_station) }

      before do
        create(:air_play, radio_station: other_radio_station, song: other_song,
                          scraper_import: true, broadcasted_at: 30.minutes.ago)
      end

      it 'returns nil for original radio station' do
        expect(scraper_importer.send(:last_added_scraper_song)).to be_nil
      end
    end
  end

  describe '#not_last_added_song' do
    context 'when song is the same as last added scraper song' do
      before do
        create(:air_play, radio_station: radio_station, song: song,
                          scraper_import: true, broadcasted_at: 30.minutes.ago)
      end

      it 'returns false to prevent duplicate import' do
        expect(scraper_importer.send(:not_last_added_song)).to be false
      end
    end

    context 'when song is different from last added scraper song' do
      before do
        create(:air_play, radio_station: radio_station, song: other_song,
                          scraper_import: true, broadcasted_at: 30.minutes.ago)
      end

      it 'returns true to allow import of different song' do
        expect(scraper_importer.send(:not_last_added_song)).to be true
      end
    end

    context 'when no scraper imports exist' do
      it 'returns true to allow first import (nil != song)' do
        expect(scraper_importer.send(:not_last_added_song)).to be true
      end
    end
  end

  describe '#may_import_song?' do
    context 'when song is the last added scraper song' do
      before do
        create(:air_play, radio_station: radio_station, song: song, scraper_import: true,
                          broadcasted_at: 30.minutes.ago, created_at: 30.minutes.ago, status: :confirmed)
      end

      it 'returns false because not_last_added_song is false (same song)' do
        expect(scraper_importer.may_import_song?).to be false
      end
    end

    context 'when song is different from last added scraper song and no recent matches' do
      before do
        create(:air_play, radio_station: radio_station, song: other_song, scraper_import: true,
                          broadcasted_at: 2.hours.ago, created_at: 2.hours.ago, status: :confirmed)
      end

      it 'returns true because not_last_added_song is true and no recent matches' do
        expect(scraper_importer.may_import_song?).to be true
      end
    end

    context 'when song is different but matches a song played in last hour' do
      before do
        create(:air_play, radio_station: radio_station, song: other_song, scraper_import: true,
                          broadcasted_at: 30.minutes.ago, created_at: 30.minutes.ago, status: :confirmed)
        create(:air_play, radio_station: radio_station, song: song, scraper_import: false,
                          broadcasted_at: 30.minutes.ago, created_at: 30.minutes.ago, status: :confirmed)
      end

      it 'returns false because any_song_matches? is true' do
        expect(scraper_importer.may_import_song?).to be false
      end
    end

    context 'when no scraper imports exist' do
      it 'returns true to allow first import' do
        expect(scraper_importer.may_import_song?).to be true
      end
    end

    context 'when song was last added but more than 1 hour ago' do
      before do
        create(:air_play, radio_station: radio_station, song: song, scraper_import: true,
                          broadcasted_at: 2.hours.ago, created_at: 2.hours.ago, status: :confirmed)
      end

      it 'returns false because not_last_added_song is false (same song still last)' do
        expect(scraper_importer.may_import_song?).to be false
      end
    end
  end

  describe 'memoization of last_added_scraper_song' do
    context 'when called multiple times' do
      before do
        create(:air_play, radio_station: radio_station, song: other_song,
                          scraper_import: true, broadcasted_at: 30.minutes.ago)
      end

      it 'returns consistent results' do
        first_call = scraper_importer.send(:last_added_scraper_song)
        second_call = scraper_importer.send(:last_added_scraper_song)
        expect(first_call).to eq(second_call)
      end
    end
  end
end
