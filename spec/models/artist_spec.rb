# == Schema Information
#
# Table name: artists
#
#  id                 :bigint           not null, primary key
#  genre              :string
#  id_on_spotify      :string
#  image              :string
#  instagram_url      :string
#  name               :string
#  spotify_artist_url :string
#  spotify_artwork_url:string
#  website_url        :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_artists_on_name  (name)
#

describe Artist do
  let(:artist_one) { create :artist }
  let(:song_one) { create :song, artists: [artist_one] }
  let(:artist_two) { create :artist }
  let(:song_two) { create :song, artists: [artist_two] }
  let(:artist_three) { create :artist }
  let(:song_three) { create :song, artists: [artist_three] }
  let(:radio_station) { create :radio_station }
  let(:air_play_one) { create :air_play, song: song_one }
  let(:air_play_two) { create :air_play, song: song_two, radio_station: }
  let(:air_play_three) { create :air_play, song: song_three, radio_station: }
  let(:air_play_four) { create :air_play, song: song_three, radio_station: }

  before do
    air_play_one
    air_play_two
    air_play_three
    air_play_four
  end

  describe '#search' do
    context 'with search term params present' do
      it 'only returns the artists matching the search term' do
        results = Artist.most_played({ search_term: artist_one.name })

        expect(results).to include artist_one
      end
    end

    context 'with radio_station_id params present' do
      it 'only returns the artists played on the radio_station' do
        results = Artist.most_played({ radio_station_id: radio_station.id })

        expect(results).to include artist_two, artist_three
      end
    end
  end

  describe '#cleanup' do
    context 'if the artist has no songs' do
      let!(:artist_no_songs) { create :artist }
      it 'destroys the artist' do
        expect {
          artist_no_songs.cleanup
        }.to change(Artist, :count).by(-1)
      end
    end

    context 'if the artist has songs' do
      it 'does not destroy the artist' do
        expect {
          artist_one.cleanup
        }.not_to change(Artist, :count)
      end
    end
  end

  describe 'TimeAnalyticsConcern' do
    let(:artist) { create(:artist) }
    let(:song) { create(:song, artists: [artist]) }
    let(:radio_station_one) { create(:radio_station) }
    let(:radio_station_two) { create(:radio_station) }

    describe '#peak_play_hours' do
      before do
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.utc(2024, 1, 15, 8, 0, 0))
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.utc(2024, 1, 15, 8, 30, 0))
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.utc(2024, 1, 15, 14, 0, 0))
        create(:air_play, song: song, radio_station: radio_station_two, broadcasted_at: Time.utc(2024, 1, 15, 20, 0, 0))
      end

      it 'returns hour distribution with play counts', :aggregate_failures do
        result = artist.peak_play_hours
        expect(result[8]).to eq(2)
        expect(result[14]).to eq(1)
        expect(result[20]).to eq(1)
      end

      it 'orders by count descending' do
        result = artist.peak_play_hours
        expect(result.keys.first).to eq(8)
      end

      context 'with radio_station_ids filter' do
        it 'filters by radio station', :aggregate_failures do
          result = artist.peak_play_hours(radio_station_ids: [radio_station_one.id])
          expect(result[8]).to eq(2)
          expect(result[14]).to eq(1)
          expect(result[20]).to be_nil
        end
      end
    end

    describe '#peak_play_days' do
      before do
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.zone.local(2024, 1, 15, 10, 0, 0)) # Monday
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.zone.local(2024, 1, 15, 14, 0, 0)) # Monday
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.zone.local(2024, 1, 19, 10, 0, 0)) # Friday
        create(:air_play, song: song, radio_station: radio_station_two, broadcasted_at: Time.zone.local(2024, 1, 21, 10, 0, 0)) # Sunday
      end

      it 'returns day of week distribution with play counts', :aggregate_failures do
        result = artist.peak_play_days
        expect(result[1]).to eq(2) # Monday
        expect(result[5]).to eq(1) # Friday
        expect(result[0]).to eq(1) # Sunday
      end

      context 'with radio_station_ids filter' do
        it 'filters by radio station', :aggregate_failures do
          result = artist.peak_play_days(radio_station_ids: [radio_station_one.id])
          expect(result[1]).to eq(2) # Monday
          expect(result[5]).to eq(1) # Friday
          expect(result[0]).to be_nil # Sunday was on radio_station_two
        end
      end
    end

    describe '#peak_play_times_summary' do
      before do
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.utc(2024, 1, 15, 8, 0, 0))
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.utc(2024, 1, 15, 8, 30, 0))
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.utc(2024, 1, 16, 14, 0, 0))
      end

      it 'returns a summary with peak hour and day', :aggregate_failures do
        result = artist.peak_play_times_summary
        expect(result[:peak_hour]).to eq(8)
        expect(result[:peak_day]).to eq(1) # Monday
        expect(result[:peak_day_name]).to eq('Monday')
      end

      it 'includes hourly distribution' do
        result = artist.peak_play_times_summary
        expect(result[:hourly_distribution][8]).to eq(2)
      end

      it 'includes daily distribution with day names' do
        result = artist.peak_play_times_summary
        expect(result[:daily_distribution]['Monday']).to eq(2)
      end
    end

    describe '#play_frequency_trend' do
      context 'with sufficient data' do
        before do
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 4.weeks.ago)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 3.weeks.ago)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 2.weeks.ago)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 2.weeks.ago + 1.day)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.week.ago)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.week.ago + 1.day)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.week.ago + 2.days)
        end

        it 'returns trend data' do
          result = artist.play_frequency_trend(weeks: 4)
          expect(result).to include(:trend, :trend_percentage, :weekly_counts, :first_period_avg, :second_period_avg)
        end

        it 'detects rising trend' do
          result = artist.play_frequency_trend(weeks: 4)
          expect(result[:trend]).to eq(:rising)
        end
      end

      context 'with insufficient data' do
        it 'returns nil when artist has no air plays' do
          new_artist = create(:artist)
          expect(new_artist.play_frequency_trend).to be_nil
        end
      end
    end

    describe '#lifecycle_stats' do
      context 'with air plays' do
        before do
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 30.days.ago)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 20.days.ago)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 10.days.ago)
          create(:air_play, song: song, radio_station: radio_station_two, broadcasted_at: 5.days.ago)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.day.ago)
        end

        it 'returns first and last play dates', :aggregate_failures do
          result = artist.lifecycle_stats
          expect(result[:first_play]).to be_within(1.minute).of(30.days.ago)
          expect(result[:last_play]).to be_within(1.minute).of(1.day.ago)
        end

        it 'returns total plays' do
          result = artist.lifecycle_stats
          expect(result[:total_plays]).to eq(5)
        end

        it 'returns days active' do
          result = artist.lifecycle_stats
          expect(result[:days_active]).to eq(30)
        end
      end

      context 'with no air plays' do
        it 'returns nil' do
          new_artist = create(:artist)
          expect(new_artist.lifecycle_stats).to be_nil
        end
      end

      context 'with radio_station_ids filter' do
        before do
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 10.days.ago)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 5.days.ago)
          create(:air_play, song: song, radio_station: radio_station_two, broadcasted_at: 1.day.ago)
        end

        it 'filters by radio station', :aggregate_failures do
          result_all = artist.lifecycle_stats
          result_filtered = artist.lifecycle_stats(radio_station_ids: [radio_station_one.id])

          expect(result_all[:total_plays]).to eq(3)
          expect(result_filtered[:total_plays]).to eq(2)
        end
      end
    end

    describe '#days_on_air' do
      context 'with air plays' do
        before do
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 10.days.ago)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.day.ago)
        end

        it 'returns the number of days between first and last play' do
          expect(artist.days_on_air).to eq(10)
        end
      end

      context 'with no air plays' do
        it 'returns 0' do
          new_artist = create(:artist)
          expect(new_artist.days_on_air).to eq(0)
        end
      end
    end

    describe '#still_playing?' do
      context 'with recent air play' do
        before do
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 3.days.ago)
        end

        it 'returns true when played within default 7 days' do
          expect(artist.still_playing?).to be true
        end

        it 'returns false when not played within custom days' do
          expect(artist.still_playing?(within_days: 2)).to be false
        end
      end

      context 'with no air plays' do
        it 'returns false' do
          new_artist = create(:artist)
          expect(new_artist.still_playing?).to be false
        end
      end
    end

    describe '#dormant?' do
      context 'with recent air play' do
        before do
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 10.days.ago)
        end

        it 'returns false when played within default 30 days' do
          expect(artist.dormant?).to be false
        end

        it 'returns true when not played within custom days' do
          expect(artist.dormant?(inactive_days: 5)).to be true
        end
      end

      context 'with no air plays' do
        it 'returns true' do
          new_artist = create(:artist)
          expect(new_artist.dormant?).to be true
        end
      end
    end
  end
end
