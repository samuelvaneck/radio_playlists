# frozen_string_literal: true

describe SongImporter do
  let(:radio_station) { create(:radio_station) }
  let(:artist) { create(:artist, name: 'Test Artist') }
  let(:song) { create(:song, title: 'Test Song', artists: [artist]) }

  describe '#add_song' do
    # These tests verify the behavior of adding a song to a radio station
    # which checks if a RadioStationSong association already exists

    context 'when song is not yet associated with radio station' do
      it 'does not have an existing association' do
        expect(RadioStationSong.exists?(radio_station: radio_station, song: song)).to be false
      end

      it 'creates a new RadioStationSong record' do
        expect do
          radio_station.songs << song
        end.to change(RadioStationSong, :count).by(1)
      end

      it 'associates the song with the radio station' do
        radio_station.songs << song
        expect(radio_station.songs).to include(song)
      end
    end

    context 'when song is already associated with radio station' do
      before do
        create(:radio_station_song, radio_station: radio_station, song: song)
      end

      it 'does not create a duplicate RadioStationSong record when using exists? check' do
        # This tests the optimized behavior
        expect do
          radio_station.songs << song unless RadioStationSong.exists?(radio_station: radio_station, song: song)
        end.not_to change(RadioStationSong, :count)
      end

      it 'RadioStationSong.exists? returns true for existing association' do
        expect(RadioStationSong.exists?(radio_station: radio_station, song: song)).to be true
      end
    end

    context 'when checking song association with multiple radio stations' do
      let(:other_radio_station) { create(:radio_station) }

      before do
        create(:radio_station_song, radio_station: radio_station, song: song)
      end

      it 'correctly identifies song is associated with first radio station' do
        expect(RadioStationSong.exists?(radio_station: radio_station, song: song)).to be true
      end

      it 'correctly identifies song is not associated with other radio station' do
        expect(RadioStationSong.exists?(radio_station: other_radio_station, song: song)).to be false
      end

      it 'can add song to other radio station' do
        expect do
          other_radio_station.songs << song unless RadioStationSong.exists?(radio_station: other_radio_station, song: song)
        end.to change(RadioStationSong, :count).by(1)
      end
    end

    context 'when radio station has many songs' do
      let!(:existing_songs) { create_list(:song, 50) }

      before do
        existing_songs.each do |s|
          create(:radio_station_song, radio_station: radio_station, song: s)
        end
      end

      it 'efficiently checks if a new song exists using exists? query' do
        new_song = create(:song)

        # This should be a single SQL EXISTS query, not loading all songs
        expect(RadioStationSong.exists?(radio_station: radio_station, song: new_song)).to be false
      end

      it 'efficiently checks if an existing song exists using exists? query' do
        existing_song = existing_songs.first

        # This should be a single SQL EXISTS query, not loading all songs
        expect(RadioStationSong.exists?(radio_station: radio_station, song: existing_song)).to be true
      end
    end

    context 'with nil values' do
      it 'returns false when song is nil' do
        expect(RadioStationSong.exists?(radio_station: radio_station, song: nil)).to be false
      end

      it 'returns false when radio_station is nil' do
        expect(RadioStationSong.exists?(radio_station: nil, song: song)).to be false
      end
    end

    context 'when adding a song' do
      let(:importer) { described_class.new(radio_station: radio_station) }
      let(:air_play) { create(:air_play, radio_station: radio_station, song: song) }

      before do
        allow(SongExternalIdsEnrichmentJob).to receive(:perform_async)
        allow(RadioStationClassifierJob).to receive(:perform_async)
        allow(Broadcaster).to receive(:song_added)
        allow(AirPlay).to receive(:add_air_play).and_return(air_play)

        importer.instance_variable_set(:@song, song)
        importer.instance_variable_set(:@artists, [artist])
        importer.instance_variable_set(:@broadcasted_at, Time.current)
        importer.instance_variable_set(:@scraper_import, false)
      end

      it 'enqueues SongExternalIdsEnrichmentJob' do
        importer.send(:add_song)

        expect(SongExternalIdsEnrichmentJob).to have_received(:perform_async).with(song.id)
      end
    end
  end
end
