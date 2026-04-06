# frozen_string_literal: true

# == Schema Information
#
# Table name: radio_stations
#
#  id                      :bigint           not null, primary key
#  avg_song_gap_per_hour   :jsonb
#  country_code            :string
#  direct_stream_url       :string
#  genre                   :string
#  import_interval         :integer
#  last_added_air_play_ids :jsonb
#  name                    :string
#  processor               :string
#  slug                    :string
#  url                     :text
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
describe RadioStation, :use_vcr, :with_valid_token do
  let(:radio_station) { create :radio_station }
  let(:air_play_4_hours_ago) { create :air_play, radio_station:, created_at: 4.hours.ago }
  let(:air_play_1_minute_ago) { create :air_play, radio_station:, created_at: 1.minute.ago }

  def processor_return_object(artist_name, title, time)
    {
      artist_name:,
      title:,
      broadcast_timestamp: Time.find_zone('Amsterdam').parse(time),
      spotify_url: nil
    }
  end

  describe '.recognizer_only' do
    it 'returns stations without a processor', :aggregate_failures do
      recognizer_station = create(:radio_station, processor: nil)
      empty_processor_station = create(:radio_station, processor: '')
      api_station = create(:radio_station, processor: 'talpa_api_processor')

      result = described_class.unscoped.recognizer_only
      expect(result).to include(recognizer_station, empty_processor_station)
      expect(result).not_to include(api_station)
    end
  end

  describe '.with_api_processor' do
    it 'returns stations with a processor', :aggregate_failures do
      recognizer_station = create(:radio_station, processor: nil)
      api_station = create(:radio_station, processor: 'talpa_api_processor')

      result = described_class.unscoped.with_api_processor
      expect(result).to include(api_station)
      expect(result).not_to include(recognizer_station)
    end
  end

  describe '#last_added_air_plays' do
    before do
      radio_station.update(last_added_air_play_ids: [air_play_4_hours_ago.id, air_play_1_minute_ago.id])
    end

    it 'returns the last created item' do
      expect(radio_station.last_added_air_plays).to contain_exactly(air_play_4_hours_ago, air_play_1_minute_ago)
    end
  end

  describe '#today_added_items' do
    it "returns all today's added items from the radio station" do
      air_play_4_hours_ago
      air_play_1_minute_ago

      expect(radio_station.today_added_items).to include air_play_4_hours_ago, air_play_1_minute_ago
    end
  end

  describe '#last_played_song' do
    context 'when no air plays exist' do
      it 'returns nil' do
        expect(radio_station.last_played_song).to be_nil
      end
    end

    context 'when air plays exist in last_added_air_play_ids' do
      before do
        radio_station.update(last_added_air_play_ids: [air_play_1_minute_ago.id])
      end

      it 'returns the song from the most recent air play' do
        expect(radio_station.last_played_song).to eq(air_play_1_minute_ago.song)
      end
    end

    context 'when multiple air plays exist in last_added_air_play_ids' do
      before do
        radio_station.update(last_added_air_play_ids: [air_play_4_hours_ago.id, air_play_1_minute_ago.id])
      end

      it 'returns the song from the most recently created air play' do
        expect(radio_station.last_played_song).to eq(air_play_1_minute_ago.song)
      end
    end

    context 'when last_added_air_play_ids is empty' do
      before do
        radio_station.update(last_added_air_play_ids: [])
      end

      it 'returns nil' do
        expect(radio_station.last_played_song).to be_nil
      end
    end

    context 'when last_added_air_play_ids contains invalid IDs' do
      before do
        radio_station.update(last_added_air_play_ids: [999_999])
      end

      it 'returns nil' do
        expect(radio_station.last_played_song).to be_nil
      end
    end
  end

  describe '.last_played_songs' do
    let(:song) { create(:song, duration_ms: 210_000) }

    context 'when the most recent air play is a draft' do
      let(:draft_air_play) { create(:air_play, radio_station:, song:, broadcasted_at: 1.minute.ago, status: :draft) }

      before do
        radio_station.update(last_added_air_play_ids: [draft_air_play.id])
      end

      it 'still returns is_currently_playing as true', :aggregate_failures do
        result = described_class.last_played_songs.find { |rs| rs[:id] == radio_station.id }

        expect(result[:is_currently_playing]).to be true
      end
    end

    context 'when only draft air plays exist and song has ended' do
      let(:draft_air_play) { create(:air_play, radio_station:, song:, broadcasted_at: 10.minutes.ago, status: :draft) }

      before do
        radio_station.update(last_added_air_play_ids: [draft_air_play.id])
      end

      it 'returns is_currently_playing as false' do
        result = described_class.last_played_songs.find { |rs| rs[:id] == radio_station.id }

        expect(result[:is_currently_playing]).to be false
      end
    end

    context 'when both draft and confirmed air plays exist' do
      let(:confirmed_air_play) { create(:air_play, radio_station:, broadcasted_at: 10.minutes.ago, status: :confirmed, created_at: 5.minutes.ago) }
      let(:draft_air_play) { create(:air_play, radio_station:, song:, broadcasted_at: 1.minute.ago, status: :draft, created_at: 1.minute.ago) }

      before do
        radio_station.update(last_added_air_play_ids: [confirmed_air_play.id, draft_air_play.id])
      end

      it 'uses the most recent air play for is_currently_playing' do
        result = described_class.last_played_songs.find { |rs| rs[:id] == radio_station.id }

        expect(result[:is_currently_playing]).to be true
      end
    end
  end

  describe '.currently_playing?' do
    context 'when air_play is nil' do
      it 'returns false' do
        expect(described_class.currently_playing?(nil)).to be false
      end
    end

    context 'when broadcasted_at is blank' do
      let(:air_play) { build(:air_play, broadcasted_at: nil).tap { |ap| ap.save(validate: false) } }

      it 'returns false' do
        expect(described_class.currently_playing?(air_play)).to be false
      end
    end

    context 'when song is within duration window' do
      let(:song) { create(:song, duration_ms: 210_000) }
      let(:air_play) { create(:air_play, song: song, broadcasted_at: 1.minute.ago) }

      it 'returns true' do
        expect(described_class.currently_playing?(air_play)).to be true
      end
    end

    context 'when song has ended' do
      let(:song) { create(:song, duration_ms: 210_000) }
      let(:air_play) { create(:air_play, song: song, broadcasted_at: 10.minutes.ago) }

      it 'returns false' do
        expect(described_class.currently_playing?(air_play)).to be false
      end
    end

    context 'when duration_ms is nil' do
      let(:song) { create(:song, duration_ms: nil) }

      context 'when within default 5-minute fallback' do
        let(:air_play) { create(:air_play, song: song, broadcasted_at: 2.minutes.ago) }

        it 'returns true' do
          expect(described_class.currently_playing?(air_play)).to be true
        end
      end

      context 'when past the default 5-minute fallback' do
        let(:air_play) { create(:air_play, song: song, broadcasted_at: 6.minutes.ago) }

        it 'returns false' do
          expect(described_class.currently_playing?(air_play)).to be false
        end
      end
    end
  end

  describe '#songs_played_last_hour' do
    let(:artist) { create(:artist) }
    let(:song_recent) { create(:song, artists: [artist]) }
    let(:song_old) { create(:song, artists: [artist]) }

    before do
      create(:air_play, radio_station: radio_station, song: song_recent, created_at: 30.minutes.ago)
      create(:air_play, radio_station: radio_station, song: song_old, created_at: 2.hours.ago)
    end

    it 'returns songs played within the last hour' do
      expect(radio_station.songs_played_last_hour).to include(song_recent)
    end

    it 'does not return songs played more than an hour ago' do
      expect(radio_station.songs_played_last_hour).not_to include(song_old)
    end

    it 'eager loads artists' do
      songs = radio_station.songs_played_last_hour.to_a
      expect(songs.first.association(:artists)).to be_loaded
    end

    context 'when a draft air play exists within the last hour' do
      let(:song_draft) { create(:song, artists: [artist]) }

      before do
        create(:air_play, radio_station: radio_station, song: song_draft, created_at: 20.minutes.ago, status: :draft)
      end

      it 'includes draft air plays in the results' do
        expect(radio_station.songs_played_last_hour).to include(song_draft)
      end
    end

    context 'when no songs played in the last hour' do
      let(:radio_station_empty) { create(:radio_station) }

      it 'returns empty relation' do
        expect(radio_station_empty.songs_played_last_hour).to be_empty
      end
    end

    context 'when the same song is played multiple times' do
      before do
        create(:air_play, radio_station: radio_station, song: song_recent,
                          created_at: 15.minutes.ago, broadcasted_at: 15.minutes.ago)
      end

      it 'returns distinct songs' do
        songs = radio_station.songs_played_last_hour.to_a
        expect(songs.count(song_recent)).to eq(1)
      end
    end
  end

  describe '#calculate_avg_song_gap_per_hour' do
    let(:song) { create(:song) }

    context 'when airplays exist within the time range' do
      let(:base_time) { Time.current.change(min: 0) }

      before do
        create(:air_play, radio_station: radio_station, song: song, broadcasted_at: base_time - 6.minutes)
        create(:air_play, radio_station: radio_station, broadcasted_at: base_time - 3.minutes)
        create(:air_play, radio_station: radio_station, broadcasted_at: base_time)
      end

      it 'calculates the average gap in seconds per hour', :aggregate_failures do
        result = radio_station.calculate_avg_song_gap_per_hour

        expect(result).to be_a(Hash)
        expect(result.values).to eq([180])
      end

      it 'persists the result to the database' do
        radio_station.calculate_avg_song_gap_per_hour

        expect(radio_station.reload.avg_song_gap_per_hour.values).to eq([180])
      end
    end

    context 'when gaps exceed 15 minutes' do
      let(:base_time) { Time.current.change(hour: 10, min: 0) }

      before do
        create(:air_play, radio_station: radio_station, song: song, broadcasted_at: base_time - 20.minutes)
        create(:air_play, radio_station: radio_station, broadcasted_at: base_time)
      end

      it 'excludes gaps over 15 minutes' do
        result = radio_station.calculate_avg_song_gap_per_hour

        expect(result).to be_empty
      end
    end

    context 'when no airplays exist' do
      it 'returns an empty hash' do
        result = radio_station.calculate_avg_song_gap_per_hour

        expect(result).to eq({})
      end
    end
  end

  describe '#expected_song_gap' do
    context 'when avg_song_gap_per_hour has data' do
      before do
        radio_station.update(avg_song_gap_per_hour: { '14' => 180, '15' => 200 })
      end

      it 'returns the gap for the given hour' do
        expect(radio_station.expected_song_gap(hour: 14)).to eq(180)
      end
    end

    context 'when no data exists for the hour' do
      before do
        radio_station.update(avg_song_gap_per_hour: { '14' => 180 })
      end

      it 'returns nil' do
        expect(radio_station.expected_song_gap(hour: 3)).to be_nil
      end
    end

    context 'when avg_song_gap_per_hour is empty' do
      it 'returns nil' do
        expect(radio_station.expected_song_gap(hour: 14)).to be_nil
      end
    end
  end

  describe '#audio_file_name' do
    it 'returns downcased name with non-word characters removed' do
      radio_station = build(:radio_station, name: 'Radio 538')

      expect(radio_station.audio_file_name).to eq('radio538')
    end

    context 'when name contains special characters' do
      it 'strips all non-word characters' do
        radio_station = build(:radio_station, name: 'Q-Music!')

        expect(radio_station.audio_file_name).to eq('qmusic')
      end
    end

    context 'when name is nil' do
      it 'returns nil' do
        radio_station = build(:radio_station, name: nil)

        expect(radio_station.audio_file_name).to be_nil
      end
    end
  end

  describe '#audio_file_path' do
    it 'returns a path under tmp/audio with the sanitized name' do
      radio_station = build(:radio_station, name: 'Radio 538')

      expect(radio_station.audio_file_path).to eq(Rails.root.join('tmp/audio/persistent/radio538.mp3'))
    end

    context 'when name contains special characters' do
      it 'returns a clean file path' do
        radio_station = build(:radio_station, name: 'Q-Music!')

        expect(radio_station.audio_file_path).to eq(Rails.root.join('tmp/audio/persistent/qmusic.mp3'))
      end
    end
  end

  describe '#npo_api_processor' do
    let(:radio_1) { described_class.find_by(name: 'Radio 1') || create(:radio_1) }

    xcontext 'given an address and radio station' do
      let(:track_data) { "TrackScraper::#{radio_1.processor&.camelcase}".constantize.new(radio_1).last_played_song }

      it 'creates a new air plays item' do
        expect(track_data).to be true
      end
    end
  end

  describe '#talpa_api_processor' do
    let(:sky_radio) { described_class.find_by(name: 'Sky Radio') || create(:sky_radio) }

    xcontext 'given an address and radio station' do
      let(:track_data) { "TrackScraper::#{sky_radio.processor&.camelcase}".constantize.new(sky_radio).last_played_song }

      it 'creates an new air plays item' do
        expect(track_data).to be true
      end
    end
  end

  describe '#scraper' do
    let(:sublime_fm) { create(:sublime_fm) }
    let(:groot_nieuws_radio) { described_class.find_by(name: 'Groot Nieuws Radio') || create(:groot_nieuws_radio) }

    xcontext 'if radio_station is Sublime FM' do
      let(:track_data) { "TrackScraper::#{sublime_fm.processor&.camelcase}".constantize.new(sublime_fm).last_played_song }

      it 'returns an artist_name, title and time' do
        expect(track_data).to be true
      end
    end

    xcontext 'if radio_station is Groot Nieuws Radio' do
      let(:track_data) { "TrackScraper::#{groot_nieuws_radio.processor&.camelcase}".constantize.new(groot_nieuws_radio).last_played_song }

      it 'returns an artist_name, titile and time' do
        expect(track_data).to be true
      end
    end
  end

  xdescribe '#radio_1_check' do
    let!(:radio_1) { create(:radio_1) }

    context 'when importing a song' do
      it 'creates a new air_play item' do
        expect do
          radio_1.import_song
        end.to change(AirPlay, :count).by(1)
      end

      it 'does not double import' do
        radio_1.import_song
        expect do
          radio_1.import_song
        end.not_to change(AirPlay, :count)
      end
    end
  end

  xdescribe '#radio_2_check' do
    let!(:radio_two) { create(:npo_radio_two) }

    context 'when importing a song' do
      it 'creates a new air play item' do
        expect do
          radio_two.import_song
        end.to change(AirPlay, :count).by(1)
      end
    end
  end

  xdescribe '#radio_3fm_check' do
    let!(:radio_3_fm) { create(:radio_3_fm) }

    context 'when importing a song' do
      it 'creates a new air play item' do
        expect do
          radio_3_fm.import_song
        end.to change(AirPlay, :count).by(1)
      end
    end
  end

  xdescribe '#radio_5_check' do
    let!(:radio_5) { create(:radio_5) }

    context 'when importing song' do
      it 'creates a new air play item' do
        expect do
          radio_5.import_song
        end.to change(AirPlay, :count).by(1)
      end
    end
  end

  xdescribe '#sky_radio_check' do
    let!(:sky_radio) { create(:sky_radio) }

    before do
      allow_any_instance_of(Spotify).to receive(:track).and_return([])
    end

    context 'when importing song' do
      it 'creates a new air play item' do
        expect do
          sky_radio.import_song
        end.to change(AirPlay, :count).by(1)
      end

      it 'does not double import' do
        sky_radio.import_song

        expect do
          sky_radio.import_song
        end.not_to change(AirPlay, :count)
      end
    end
  end

  xdescribe '#radio_veronica_check' do
    let!(:radio_veronica) { create(:radio_veronica) }

    before do
      allow_any_instance_of(Spotify).to receive(:track).and_return([])
    end

    context 'when importing song' do
      it 'creates a new air play item' do
        expect do
          radio_veronica.import_song
        end.to change(AirPlay, :count).by(1)
      end
    end
  end

  xdescribe '#radio_538_check' do
    let(:radio_538) { create(:radio_538) }

    before do
      allow_any_instance_of(Spotify).to receive(:track).and_return([])
    end

    context 'when importing song' do
      it 'creates a new air play item' do
        expect do
          radio_538.import_song
        end.to change(AirPlay, :count).by(1)
      end
    end
  end

  xdescribe '#radio_10_check' do
    let!(:radio_10) { create(:radio_10) }

    before do
      allow_any_instance_of(Spotify).to receive(:track).and_return([])
    end

    context 'when importing song' do
      it 'creates a new air play item' do
        expect do
          radio_10.import_song
        end.to change(AirPlay, :count).by(1)
      end
    end
  end

  xdescribe '#q_music_check' do
    let!(:qmusic) { create(:qmusic) }

    context 'when importing song' do
      it 'creates a new air play item' do
        expect do
          qmusic.import_song
        end.to change(AirPlay, :count).by(1)
      end

      it 'does not double import' do
        qmusic.import_song

        expect do
          qmusic.import_song
        end.not_to change(AirPlay, :count)
      end
    end
  end

  xdescribe '#sublime_fm_check' do
    let!(:sublime_fm) { create(:sublime_fm) }

    context 'when importing song' do
      it 'creates a new air play item' do
        expect do
          sublime_fm.import_song
        end.to change(AirPlay, :count).by(1)
      end
    end
  end

  xdescribe '#grootnieuws_radio_check' do
    let!(:groot_nieuws_radio) { create(:groot_nieuws_radio) }

    context 'when importing song' do
      it 'creates a new air play item' do
        expect do
          groot_nieuws_radio.import_song
        end.to change(AirPlay, :count).by(1)
      end
    end
  end

  # describe '#illegal_word_in_title' do
  #   context 'a title with more then 4 digits' do
  #     it 'returns false' do
  #       expect(described_class.new.illegal_word_in_title('test 1234')).to eq true
  #     end
  #   end
  #
  #   context 'a title with a forward slash' do
  #     it 'returns false' do
  #       expect(described_class.new.illegal_word_in_title('test / go ')).to eq true
  #     end
  #   end
  #
  #   context 'a title with 2 single qoutes' do
  #     it 'returns false' do
  #       expect(described_class.new.illegal_word_in_title("test''s")).to eq true
  #     end
  #   end
  #
  #   context 'a titlle that has reklame or reclame' do
  #     it 'returns false' do
  #       expect(described_class.new.illegal_word_in_title('test reclame')).to eq true
  #     end
  #   end
  #
  #   context 'a title that has more then two dots' do
  #     it 'returns false' do
  #       expect(described_class.new.illegal_word_in_title('test..test')).to eq true
  #     end
  #   end
  #
  #   context 'when the title contains "nieuws"' do
  #     it 'returns false' do
  #       expect(described_class.new.illegal_word_in_title('ANP NIEUWS')).to eq true
  #     end
  #   end
  #
  #   context 'when the title contains "pingel"' do
  #     it 'returns false' do
  #       expect(described_class.new.illegal_word_in_title('Kerst pingel')).to eq true
  #     end
  #   end
  #
  #   context 'any other title' do
  #     it 'returns true' do
  #       expect(described_class.new.illegal_word_in_title('Liquid Spirit')).to eq false
  #     end
  #   end
  # end

  # describe '#find_or_create_artist' do
  #   context 'with multiple name' do
  #     it 'returns the artists and not a karaoke version' do
  #       spotify_track = Spotify::TrackFinder::Result.new(artists: 'Martin Garrix & Clinton Kane', title: 'Drown')
  #       spotify_track.execute
  #       result = described_class.new.find_or_create_artist('Martin Garrix & Clinton Kane', spotify_track)
  #
  #       expect(result.map(&:name)).to contain_exactly 'Martin Garrix', 'Clinton Kane'
  #     end
  #   end
  # end

  # describe '#find_or_create_song' do
  #   let!(:song_in_your_eyes_robin_schulz) { create :song, title: 'In Your Eyes', artists: [artist_robin_schulz, artist_alida] }
  #   let!(:song_in_your_eyes_weekend) { create :song, title: 'In Your Eyes', artists: [artist_the_weeknd] }
  #   let!(:artist_the_weeknd) { create :artist, name: 'The Weeknd' }
  #   let!(:artist_robin_schulz) { create :artist, name: 'Robin Schulz' }
  #   let!(:artist_alida) { create :artist, name: 'Alida' }
  #
  #   context 'with a song present with the same name but different artist(s)' do
  #     it 'creates a new artist' do
  #       song = described_class.new.song_check([song_in_your_eyes_robin_schulz], [artist_the_weeknd], 'In Your Eyes')
  #
  #       expect(song.artists).to contain_exactly artist_the_weeknd
  #     end
  #   end
  #
  #   context 'when the song is present with the same artist(s)' do
  #     it 'doesnt create a new artist' do
  #       song = described_class.new.song_check([song_in_your_eyes_weekend], [artist_the_weeknd], 'In Your Eyes')
  #
  #       expect(song.artists).to contain_exactly artist_the_weeknd
  #     end
  #   end
  #
  #   context 'when the title is differently capitalized' do
  #     it 'it doesnt create a new song but finds the existing one' do
  #       song = nil
  #       expect do
  #         song = described_class.new.song_check([song_in_your_eyes_weekend], [artist_the_weeknd], 'In your eyes')
  #       end.to change(AirPlay, :count).by(0)
  #
  #       expect(song.title).to eq 'In Your Eyes'
  #     end
  #   end
  # end
end
