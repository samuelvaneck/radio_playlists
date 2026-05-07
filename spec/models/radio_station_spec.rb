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
describe RadioStation do
  let(:radio_station) { create :radio_station }
  let(:air_play_4_hours_ago) { create :air_play, radio_station:, created_at: 4.hours.ago }
  let(:air_play_1_minute_ago) { create :air_play, radio_station:, created_at: 1.minute.ago }

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

  describe '#update_last_added_air_play_ids' do
    let(:air_play) { create(:air_play, radio_station:) }

    it 'appends the air play id to the list' do
      radio_station.update_last_added_air_play_ids(air_play.id)
      expect(radio_station.reload.last_added_air_play_ids).to eq([air_play.id])
    end

    it 'caps the list at 12 entries' do
      radio_station.update!(last_added_air_play_ids: (1..12).to_a)
      radio_station.update_last_added_air_play_ids(air_play.id)
      expect(radio_station.reload.last_added_air_play_ids).to eq((2..12).to_a + [air_play.id])
    end

    it 'does not run the name uniqueness query when name is unchanged' do
      ids = [radio_station.id, air_play.id]
      queries = []
      ActiveSupport::Notifications.subscribed(->(*a) { queries << a.last[:sql] }, 'sql.active_record') do
        described_class.find(ids[0]).update_last_added_air_play_ids(ids[1])
      end
      expect(queries.compact).to all(satisfy { |sql| !sql.match?(/SELECT 1.*FROM "radio_stations".*"name"/m) })
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
end
