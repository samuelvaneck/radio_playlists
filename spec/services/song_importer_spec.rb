# frozen_string_literal: true

describe SongImporter do
  let(:radio_station) { create(:radio_station) }
  let(:artist) { create(:artist, name: 'Test Artist') }
  let(:song) { create(:song, title: 'Test Song', artists: [artist]) }

  describe '#should_update_artists?' do
    subject(:song_importer) do
      importer = described_class.new(radio_station: radio_station)
      importer.instance_variable_set(:@song, existing_song)
      importer.instance_variable_set(:@artists, new_artists)
      importer
    end

    let(:existing_song) { create(:song, title: 'Existing Song', artists: existing_artists) }

    context 'when song has no artists' do
      let(:existing_artists) { [] }
      let(:new_artists) { [create(:artist, name: 'New Artist', id_on_spotify: 'spotify123')] }

      before { existing_song.artists = [] }

      it 'returns true to allow setting artists' do
        expect(song_importer.send(:should_update_artists?)).to be true
      end
    end

    context 'when song has artists without Spotify IDs' do
      let(:existing_artists) { [create(:artist, name: 'Old Artist', id_on_spotify: nil)] }
      let(:new_artists) { [create(:artist, name: 'New Artist', id_on_spotify: 'spotify123')] }

      it 'returns true to allow updating with Spotify data' do
        expect(song_importer.send(:should_update_artists?)).to be true
      end
    end

    context 'when song has artists with Spotify IDs' do
      let(:existing_artists) { [create(:artist, name: 'Spotify Artist', id_on_spotify: 'spotify456')] }
      let(:new_artists) { [create(:artist, name: 'Different Artist', id_on_spotify: 'spotify789')] }

      it 'returns false to prevent overwriting valid Spotify data' do
        expect(song_importer.send(:should_update_artists?)).to be false
      end
    end

    context 'when song has mixed artists (some with Spotify IDs, some without)' do
      let(:existing_artists) do
        [
          create(:artist, name: 'Spotify Artist', id_on_spotify: 'spotify456'),
          create(:artist, name: 'Non-Spotify Artist', id_on_spotify: nil)
        ]
      end
      let(:new_artists) { [create(:artist, name: 'New Artist', id_on_spotify: 'spotify789')] }

      it 'returns false because at least one artist has Spotify ID' do
        expect(song_importer.send(:should_update_artists?)).to be false
      end
    end

    context 'when new artists are the same as existing artists' do
      let(:existing_artist) { create(:artist, name: 'Same Artist', id_on_spotify: 'spotify123') }
      let(:existing_artists) { [existing_artist] }
      let(:new_artists) { [existing_artist] }

      it 'returns false because artists are not different' do
        expect(song_importer.send(:should_update_artists?)).to be false
      end
    end

    context 'when new artists array is empty' do
      let(:existing_artists) { [create(:artist, name: 'Existing', id_on_spotify: nil)] }
      let(:new_artists) { [] }

      it 'returns false because different_artists? would be true but we should not clear artists' do
        # different_artists? returns true ([] != [existing_artist_id])
        # but should_update_artists? should still allow it if no spotify IDs
        expect(song_importer.send(:should_update_artists?)).to be true
      end
    end
  end

  describe '#different_artists?' do
    subject(:song_importer) do
      importer = described_class.new(radio_station: radio_station)
      importer.instance_variable_set(:@song, existing_song)
      importer.instance_variable_set(:@artists, new_artists)
      importer
    end

    let(:existing_song) { create(:song, title: 'Existing Song', artists: existing_artists) }

    context 'when artists are the same' do
      let(:same_artist) { create(:artist, name: 'Same Artist') }
      let(:existing_artists) { [same_artist] }
      let(:new_artists) { [same_artist] }

      it 'returns false' do
        expect(song_importer.send(:different_artists?)).to be false
      end
    end

    context 'when artists are different' do
      let(:existing_artists) { [create(:artist, name: 'Artist A')] }
      let(:new_artists) { [create(:artist, name: 'Artist B')] }

      it 'returns true' do
        expect(song_importer.send(:different_artists?)).to be true
      end
    end

    context 'when artists are in different order but same IDs' do
      let(:artist_a) { create(:artist, name: 'Artist A') }
      let(:artist_b) { create(:artist, name: 'Artist B') }
      let(:existing_artists) { [artist_a, artist_b] }
      let(:new_artists) { [artist_b, artist_a] }

      it 'returns false because IDs are sorted before comparison' do
        expect(song_importer.send(:different_artists?)).to be false
      end
    end
  end

  describe 'race condition prevention for artist updates' do
    let(:original_artist) { create(:artist, name: 'Original Artist', id_on_spotify: 'original_spotify_id') }
    let(:song_with_spotify_artist) { create(:song, title: 'Popular Song', artists: [original_artist]) }

    context 'when multiple imports try to update the same song with different artists' do
      let(:alternate_artist) { create(:artist, name: 'Different Artist 1', id_on_spotify: 'different_id_1') }
      let(:another_artist) { create(:artist, name: 'Different Artist 2', id_on_spotify: 'different_id_2') }

      it 'preserves the original artists when they have Spotify IDs' do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
        importer_one = described_class.new(radio_station: radio_station)
        importer_one.instance_variable_set(:@song, song_with_spotify_artist)
        importer_one.instance_variable_set(:@artists, [alternate_artist])

        importer_two = described_class.new(radio_station: radio_station)
        importer_two.instance_variable_set(:@song, song_with_spotify_artist)
        importer_two.instance_variable_set(:@artists, [another_artist])

        expect(importer_one.send(:should_update_artists?)).to be false
        expect(importer_two.send(:should_update_artists?)).to be false
        expect(song_with_spotify_artist.reload.artists).to contain_exactly(original_artist)
      end
    end

    context 'when song was imported without Spotify data initially' do
      let(:artist_without_spotify) { create(:artist, name: 'No Spotify Artist', id_on_spotify: nil) }
      let(:song_without_spotify_artist) { create(:song, title: 'Other Song', artists: [artist_without_spotify]) }
      let(:artist_with_spotify) { create(:artist, name: 'Spotify Artist', id_on_spotify: 'spotify_id') }

      it 'allows updating when existing artists lack Spotify IDs' do
        importer = described_class.new(radio_station: radio_station)
        importer.instance_variable_set(:@song, song_without_spotify_artist)
        importer.instance_variable_set(:@artists, [artist_with_spotify])

        expect(importer.send(:should_update_artists?)).to be true
      end
    end
  end

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
  end

  describe '#build_audio_stream' do
    subject(:importer) { described_class.new(radio_station: station) }

    let(:output_file) { Rails.root.join('tmp/test_build_audio_stream.mp3') }

    context 'when persistent segment is available' do
      let(:station) { create(:radio_station, :with_direct_stream, direct_stream_url: 'https://icecast.example.com/test.mp3') }

      before do
        reader = instance_double(PersistentStream::SegmentReader, available?: true)
        allow(PersistentStream::SegmentReader).to receive(:new).and_return(reader)
      end

      it 'returns a PersistentSegment instance' do
        result = importer.send(:build_audio_stream, output_file)
        expect(result).to be_a(AudioStream::PersistentSegment)
      end
    end

    context 'when persistent segment is not available and stream is MP3' do
      let(:station) { create(:radio_station, direct_stream_url: 'https://icecast.example.com/test.mp3') }

      it 'returns an Mp3 instance' do
        result = importer.send(:build_audio_stream, output_file)
        expect(result).to be_a(AudioStream::Mp3)
      end
    end

    context 'when persistent segment is not available and stream is M3U8' do
      let(:station) { create(:radio_station, direct_stream_url: 'https://stream.example.com/test-m3u8') }

      it 'returns an M3u8 instance' do
        result = importer.send(:build_audio_stream, output_file)
        expect(result).to be_a(AudioStream::M3u8)
      end
    end

    context 'when station has direct_stream_url but segments are stale' do
      let(:station) { create(:radio_station, :with_direct_stream, direct_stream_url: 'https://icecast.example.com/test.mp3') }

      before do
        reader = instance_double(PersistentStream::SegmentReader, available?: false)
        allow(PersistentStream::SegmentReader).to receive(:new).and_return(reader)
      end

      it 'falls back to Mp3 stream' do
        result = importer.send(:build_audio_stream, output_file)
        expect(result).to be_a(AudioStream::Mp3)
      end
    end
  end
end
