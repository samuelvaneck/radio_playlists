# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TimeAnalyticsConcern do
  let(:artist) { create(:artist, name: 'Test Artist') }
  let(:song) { create(:song, title: 'Test Song', artists: [artist]) }
  let(:radio_station_one) { create(:radio_station) }
  let(:radio_station_two) { create(:radio_station) }

  describe '#peak_play_hours' do
    let!(:air_play_8am_1) { create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.utc(2024, 1, 15, 8, 0, 0)) }
    let!(:air_play_8am_2) { create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.utc(2024, 1, 15, 8, 30, 0)) }
    let!(:air_play_14pm) { create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.utc(2024, 1, 15, 14, 0, 0)) }
    let!(:air_play_20pm) { create(:air_play, song: song, radio_station: radio_station_two, broadcasted_at: Time.utc(2024, 1, 15, 20, 0, 0)) }

    it 'returns hour distribution with play counts' do
      result = song.peak_play_hours
      expect(result[8]).to eq(2)
      expect(result[14]).to eq(1)
      expect(result[20]).to eq(1)
    end

    it 'orders by count descending' do
      result = song.peak_play_hours
      expect(result.keys.first).to eq(8)
    end

    context 'with radio_station_ids filter' do
      it 'filters by radio station' do
        result = song.peak_play_hours(radio_station_ids: [radio_station_one.id])
        expect(result[8]).to eq(2)
        expect(result[14]).to eq(1)
        expect(result[20]).to be_nil
      end
    end
  end

  describe '#peak_play_days' do
    before do
      # Monday = 1, Friday = 5, Sunday = 0
      create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.zone.local(2024, 1, 15, 10, 0, 0)) # Monday
      create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.zone.local(2024, 1, 15, 14, 0, 0)) # Monday
      create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.zone.local(2024, 1, 19, 10, 0, 0)) # Friday
      create(:air_play, song: song, radio_station: radio_station_two, broadcasted_at: Time.zone.local(2024, 1, 21, 10, 0, 0)) # Sunday
    end

    it 'returns day of week distribution with play counts' do
      result = song.peak_play_days
      expect(result[1]).to eq(2) # Monday
      expect(result[5]).to eq(1) # Friday
      expect(result[0]).to eq(1) # Sunday
    end

    it 'orders by count descending' do
      result = song.peak_play_days
      expect(result.keys.first).to eq(1) # Monday has most plays
    end

    context 'with radio_station_ids filter' do
      it 'filters by radio station' do
        result = song.peak_play_days(radio_station_ids: [radio_station_one.id])
        expect(result[1]).to eq(2) # Monday
        expect(result[5]).to eq(1) # Friday
        expect(result[0]).to be_nil # Sunday was on radio_station_two
      end
    end
  end

  describe '#peak_play_times_summary' do
    # Using UTC times - Jan 15, 2024 is a Monday
    let!(:air_play_monday_8am_1) { create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.utc(2024, 1, 15, 8, 0, 0)) }
    let!(:air_play_monday_8am_2) { create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.utc(2024, 1, 15, 8, 30, 0)) }
    let!(:air_play_tuesday_14pm) { create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.utc(2024, 1, 16, 14, 0, 0)) }

    it 'returns a summary with peak hour and day' do
      result = song.peak_play_times_summary
      expect(result[:peak_hour]).to eq(8)
      expect(result[:peak_day]).to eq(1) # Monday
      expect(result[:peak_day_name]).to eq('Monday')
    end

    it 'includes hourly distribution' do
      result = song.peak_play_times_summary
      expect(result[:hourly_distribution]).to be_a(Hash)
      expect(result[:hourly_distribution][8]).to eq(2)
    end

    it 'includes daily distribution with day names' do
      result = song.peak_play_times_summary
      expect(result[:daily_distribution]).to be_a(Hash)
      expect(result[:daily_distribution]['Monday']).to eq(2)
      expect(result[:daily_distribution]['Tuesday']).to eq(1)
    end
  end

  describe '#play_frequency_trend' do
    context 'with sufficient data' do
      before do
        # Week 1-2: lower plays (first half)
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 4.weeks.ago)
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 3.weeks.ago)
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 3.weeks.ago + 1.day)

        # Week 3-4: higher plays (second half)
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 2.weeks.ago)
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 2.weeks.ago + 1.day)
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.week.ago)
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.week.ago + 1.day)
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.week.ago + 2.days)
      end

      it 'returns trend data' do
        result = song.play_frequency_trend(weeks: 4)
        expect(result).to include(:trend, :trend_percentage, :weekly_counts, :first_period_avg, :second_period_avg)
      end

      it 'detects rising trend' do
        result = song.play_frequency_trend(weeks: 4)
        expect(result[:trend]).to eq(:rising)
        expect(result[:trend_percentage]).to be > 10
      end

      it 'includes weekly counts' do
        result = song.play_frequency_trend(weeks: 4)
        expect(result[:weekly_counts]).to be_a(Hash)
      end
    end

    context 'with declining plays' do
      before do
        # Week 1-2: higher plays (first half)
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 4.weeks.ago)
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 4.weeks.ago + 1.day)
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 4.weeks.ago + 2.days)
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 3.weeks.ago)
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 3.weeks.ago + 1.day)

        # Week 3-4: lower plays (second half)
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 2.weeks.ago)
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.week.ago)
      end

      it 'detects falling trend' do
        result = song.play_frequency_trend(weeks: 4)
        expect(result[:trend]).to eq(:falling)
        expect(result[:trend_percentage]).to be < -10
      end
    end

    context 'with insufficient data' do
      it 'returns nil when song has no air plays' do
        new_song = create(:song)
        expect(new_song.play_frequency_trend).to be_nil
      end

      it 'returns nil when only one week of data' do
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.day.ago)
        expect(song.play_frequency_trend(weeks: 4)).to be_nil
      end
    end

    context 'with radio_station_ids filter' do
      before do
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 3.weeks.ago)
        create(:air_play, song: song, radio_station: radio_station_two, broadcasted_at: 3.weeks.ago + 1.day)
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.week.ago)
        create(:air_play, song: song, radio_station: radio_station_two, broadcasted_at: 1.week.ago + 1.day)
      end

      it 'filters by radio station' do
        result_all = song.play_frequency_trend(weeks: 4)
        result_filtered = song.play_frequency_trend(weeks: 4, radio_station_ids: [radio_station_one.id])

        total_all = result_all[:weekly_counts].values.sum
        total_filtered = result_filtered[:weekly_counts].values.sum

        expect(total_filtered).to be < total_all
      end
    end
  end

  describe '#trending_up?' do
    before do
      create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 3.weeks.ago)
      create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.week.ago)
      create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.week.ago + 1.day)
      create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.week.ago + 2.days)
    end

    it 'returns true when song is trending up' do
      expect(song.trending_up?(weeks: 4)).to be true
    end

    it 'returns false when song is not trending up' do
      expect(song.trending_down?(weeks: 4)).to be false
    end
  end

  describe '#trending_down?' do
    before do
      create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 3.weeks.ago)
      create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 3.weeks.ago + 1.day)
      create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 3.weeks.ago + 2.days)
      create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.week.ago)
    end

    it 'returns true when song is trending down' do
      expect(song.trending_down?(weeks: 4)).to be true
    end

    it 'returns false when song is not trending down' do
      expect(song.trending_up?(weeks: 4)).to be false
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

      it 'returns first and last play dates' do
        result = song.lifecycle_stats
        expect(result[:first_play]).to be_within(1.minute).of(30.days.ago)
        expect(result[:last_play]).to be_within(1.minute).of(1.day.ago)
      end

      it 'returns total plays' do
        result = song.lifecycle_stats
        expect(result[:total_plays]).to eq(5)
      end

      it 'returns days since first and last play' do
        result = song.lifecycle_stats
        expect(result[:days_since_first_play]).to eq(30)
        expect(result[:days_since_last_play]).to eq(1)
      end

      it 'returns days active' do
        result = song.lifecycle_stats
        expect(result[:days_active]).to eq(30) # 30 days - 1 day + 1 = 30 days span
      end

      it 'returns unique days played' do
        result = song.lifecycle_stats
        expect(result[:unique_days_played]).to eq(5)
      end

      it 'returns average plays per day' do
        result = song.lifecycle_stats
        expect(result[:average_plays_per_day]).to be_a(Float)
        expect(result[:average_plays_per_day]).to be > 0
      end

      it 'returns play consistency percentage' do
        result = song.lifecycle_stats
        expect(result[:play_consistency]).to be_a(Float)
        expect(result[:play_consistency]).to be_between(0, 100)
      end
    end

    context 'with no air plays' do
      it 'returns nil' do
        new_song = create(:song)
        expect(new_song.lifecycle_stats).to be_nil
      end
    end

    context 'with radio_station_ids filter' do
      before do
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 10.days.ago)
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 5.days.ago)
        create(:air_play, song: song, radio_station: radio_station_two, broadcasted_at: 1.day.ago)
      end

      it 'filters by radio station' do
        result_all = song.lifecycle_stats
        result_filtered = song.lifecycle_stats(radio_station_ids: [radio_station_one.id])

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
        expect(song.days_on_air).to eq(10)
      end
    end

    context 'with no air plays' do
      it 'returns 0' do
        new_song = create(:song)
        expect(new_song.days_on_air).to eq(0)
      end
    end
  end

  describe '#still_playing?' do
    context 'with recent air play' do
      before do
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 3.days.ago)
      end

      it 'returns true when played within default 7 days' do
        expect(song.still_playing?).to be true
      end

      it 'returns true when played within custom days' do
        expect(song.still_playing?(within_days: 5)).to be true
      end

      it 'returns false when not played within custom days' do
        expect(song.still_playing?(within_days: 2)).to be false
      end
    end

    context 'with no recent air play' do
      before do
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 10.days.ago)
      end

      it 'returns false when not played within 7 days' do
        expect(song.still_playing?).to be false
      end
    end

    context 'with no air plays' do
      it 'returns false' do
        new_song = create(:song)
        expect(new_song.still_playing?).to be false
      end
    end
  end

  describe '#dormant?' do
    context 'with recent air play' do
      before do
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 10.days.ago)
      end

      it 'returns false when played within default 30 days' do
        expect(song.dormant?).to be false
      end

      it 'returns true when not played within custom days' do
        expect(song.dormant?(inactive_days: 5)).to be true
      end
    end

    context 'with no recent air play' do
      before do
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 60.days.ago)
      end

      it 'returns true when not played within 30 days' do
        expect(song.dormant?).to be true
      end
    end

    context 'with no air plays' do
      it 'returns true' do
        new_song = create(:song)
        expect(new_song.dormant?).to be true
      end
    end
  end
end
