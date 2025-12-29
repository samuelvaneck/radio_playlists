# frozen_string_literal: true

describe SongImporter::RecognizerImporter do
  subject(:recognizer_importer) do
    described_class.new(radio_station: radio_station, artists: [artist], song: song)
  end

  let(:radio_station) { create(:radio_station) }
  let(:artist) { create(:artist, name: 'Test Artist') }
  let(:song) { create(:song, title: 'Test Song', artists: [artist]) }
  let(:other_song) { create(:song, title: 'Other Song', artists: [artist]) }

  describe '#not_last_added_song' do
    context 'when no air plays exist (last_played_song is nil)' do
      it 'returns true' do
        expect(recognizer_importer.send(:not_last_added_song)).to be true
      end
    end

    context 'when song is the same as last played song' do
      before do
        air_play = create(:air_play, radio_station: radio_station, song: song, broadcasted_at: 10.minutes.ago)
        radio_station.update(last_added_air_play_ids: [air_play.id])
      end

      it 'returns false' do
        expect(recognizer_importer.send(:not_last_added_song)).to be false
      end
    end

    context 'when song is different from last played song' do
      before do
        air_play = create(:air_play, radio_station: radio_station, song: other_song, broadcasted_at: 10.minutes.ago)
        radio_station.update(last_added_air_play_ids: [air_play.id])
      end

      it 'returns true' do
        expect(recognizer_importer.send(:not_last_added_song)).to be true
      end
    end

    context 'when multiple air plays exist' do
      before do
        older_air_play = create(:air_play, radio_station: radio_station, song: other_song, broadcasted_at: 1.hour.ago, created_at: 1.hour.ago)
        newer_air_play = create(:air_play, radio_station: radio_station, song: song, broadcasted_at: 10.minutes.ago, created_at: 10.minutes.ago)
        radio_station.update(last_added_air_play_ids: [older_air_play.id, newer_air_play.id])
      end

      it 'compares against the most recent air play' do
        # The most recent is song, so comparing song to song should return false
        expect(recognizer_importer.send(:not_last_added_song)).to be false
      end
    end
  end

  describe '#may_import_song?' do
    context 'when song is not the last played and no matches exist' do
      let(:completely_different_artist) { create(:artist, name: 'Completely Different') }
      let(:completely_different_song) { create(:song, title: 'XYZ Unrelated Track', artists: [completely_different_artist]) }

      before do
        # Use a completely different song to avoid any similarity match
        air_play = create(:air_play, radio_station: radio_station, song: completely_different_song, broadcasted_at: 2.hours.ago,
                                     created_at: 2.hours.ago)
        radio_station.update(last_added_air_play_ids: [air_play.id])
      end

      it 'returns true' do
        expect(recognizer_importer.may_import_song?).to be true
      end
    end

    context 'when song is not the last played but matches exist in last hour' do
      before do
        # Different song as last played, but our song was played recently (within last hour)
        air_play_other = create(:air_play, radio_station: radio_station, song: other_song, broadcasted_at: 10.minutes.ago, created_at: 10.minutes.ago)
        # Our target song was also played recently - this creates a match
        create(:air_play, radio_station: radio_station, song: song, broadcasted_at: 30.minutes.ago, created_at: 30.minutes.ago)
        radio_station.update(last_added_air_play_ids: [air_play_other.id])
      end

      it 'returns false because matches exist' do
        expect(recognizer_importer.may_import_song?).to be false
      end
    end

    context 'when song is the last played' do
      before do
        air_play = create(:air_play, radio_station: radio_station, song: song, broadcasted_at: 10.minutes.ago, created_at: 10.minutes.ago)
        radio_station.update(last_added_air_play_ids: [air_play.id])
      end

      it 'returns false' do
        expect(recognizer_importer.may_import_song?).to be false
      end
    end

    context 'when no previous air plays exist' do
      it 'returns true' do
        expect(recognizer_importer.may_import_song?).to be true
      end
    end
  end

  describe '#broadcast_error_message' do
    it 'broadcasts the error message' do
      allow(Broadcaster).to receive(:last_song)
      recognizer_importer.broadcast_error_message
      expect(Broadcaster).to have_received(:last_song).with(
        title: song.title,
        artists_names: artist.name,
        radio_station_name: radio_station.name
      )
    end
  end
end
