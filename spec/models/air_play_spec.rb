# frozen_string_literal: true

# == Schema Information
#
# Table name: air_plays
#
#  id               :bigint           not null, primary key
#  broadcasted_at   :datetime
#  scraper_import   :boolean          default(FALSE)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  radio_station_id :bigint
#  song_id          :bigint
#
# Indexes
#
#  air_play_radio_song_time             (song_id,radio_station_id,broadcasted_at) UNIQUE
#  index_air_plays_on_radio_station_id  (radio_station_id)
#  index_air_plays_on_song_id           (song_id)
#
# Foreign Keys
#
#  fk_rails_...  (radio_station_id => radio_stations.id)
#  fk_rails_...  (song_id => songs.id)
#
describe AirPlay do
  let(:artist_one) { create :artist }
  let(:song_one) { create :song, artists: [artist_one] }
  let(:artist_two) { create :artist }
  let(:song_two) { create :song, artists: [artist_two] }
  let(:artist_three) { create :artist, name: 'Robin Schulz' }
  let(:song_three) { create :song, artists: [artist_three] }
  let(:artist_four) { create :artist, name: 'Erika Sirola' }
  let(:song_four) { create :song, artists: [artist_four] }
  let(:radio_station) { create :radio_station }
  let(:air_play_one) { create :air_play, song: song_one, radio_station: }
  let(:air_play_two) { create :air_play, song: song_two, radio_station: }
  let(:air_play_three) { create :air_play, song: song_two, radio_station: }

  describe '#search' do
    before do
      air_play_one
      air_play_two
      air_play_three
    end

    context 'with search term params' do
      it 'returns the air plays artist name or song title that matches the search terms' do
        expected = [air_play_one]

        expect(described_class.last_played({ search_term: song_one.title })).to eq expected
      end
    end

    context 'with radio_stations params' do
      it 'returns the air plays played on the radio station' do
        expect(described_class.last_played({ radio_station_ids: [radio_station.id] })).to include air_play_two, air_play_three
      end
    end

    context 'with no params' do
      it 'returns all the air plays' do
        expect(described_class.last_played({})).to include air_play_one, air_play_two, air_play_three
      end
    end
  end

  describe '#today_unique_air_plays_item' do
    before { air_play_one }

    context 'with an already air play existing item' do
      it 'fails validation' do
        new_air_play_item = described_class.new(broadcasted_at: air_play_one.broadcasted_at,
                                                song: air_play_one.song,
                                                radio_station: air_play_one.radio_station)

        expect(new_air_play_item.valid?).to be false
      end
    end

    context 'with a unique air play item' do
      it 'does not fail validation' do
        new_air_play_item = build :air_play

        expect(new_air_play_item.valid?).to be true
      end
    end
  end

  describe '#deduplicate' do
    let!(:air_play_one) { create :air_play }

    context 'if there are no duplicate entries' do
      it 'does not delete the air play item' do
        expect do
          air_play_one.deduplicate
        end.not_to change(described_class, :count)
      end
    end

    context 'if duplicate entries exists' do
      before do
        air_play = build(:air_play,
                         radio_station: air_play_one.radio_station,
                         broadcasted_at: air_play_one.broadcasted_at)
        air_play.save(validate: false)
      end

      it 'deletes the air play item' do
        expect do
          air_play_one.deduplicate
        end.to change(described_class, :count).by(-1)
      end
    end

    context 'if there are duplicates and the song has no more air play items' do
      before do
        air_play = build(:air_play,
                         radio_station: air_play_one.radio_station,
                         broadcasted_at: air_play_one.broadcasted_at)
        air_play.save(validate: false)
      end

      it 'deletes the song' do
        expect do
          air_play_one.deduplicate
        end.to change(Song, :count).by(-1)
      end
    end

    context 'if there are duplicates and the air play song has more air plays items' do
      before do
        air_play = build(:air_play,
                         radio_station: air_play_one.radio_station,
                         broadcasted_at: air_play_one.broadcasted_at)
        air_play.save(validate: false)
        create(:air_play, song: air_play_one.song)
      end

      it 'does not delete the song' do
        expect do
          air_play_one.deduplicate
        end.not_to change(Song, :count)
      end
    end
  end

  describe '#duplicate?' do
    let!(:air_play_one) { create(:air_play) }

    context 'with duplicates present' do
      before do
        air_play = build(:air_play,
                         radio_station: air_play_one.radio_station,
                         broadcasted_at: air_play_one.broadcasted_at)
        air_play.save(validate: false)
      end

      it 'returns true' do
        expect(air_play_one.duplicate?).to be true
      end
    end

    context 'without duplicates' do
      it 'returns false' do
        expect(air_play_one.duplicate?).to be false
      end
    end
  end
end
