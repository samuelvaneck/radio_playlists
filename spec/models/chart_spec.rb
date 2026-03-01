# frozen_string_literal: true

describe Chart do
  describe '#create_chart_positions' do
    let(:radio_station) { create(:radio_station) }

    context 'when songs have the same daily airplay count but different popularity', :aggregate_failures do
      let(:chart) { create(:chart, chart_type: 'songs', date: Time.zone.today) }
      let(:popular_song) do
        create(:song, title: 'Popular Song', popularity: 90, lastfm_listeners: 50_000_000, lastfm_playcount: 500_000_000)
      end
      let(:unpopular_song) do
        create(:song, title: 'Unpopular Song', popularity: 10, lastfm_listeners: 1_000, lastfm_playcount: 5_000)
      end

      before do
        # Both songs get the same daily airplay count (2 plays yesterday)
        2.times do
          create(:air_play, song: popular_song, radio_station:, broadcasted_at: 1.day.ago)
          create(:air_play, song: unpopular_song, radio_station:, broadcasted_at: 1.day.ago)
        end
        # Same weekly airplay count too — popularity boost becomes the differentiator
        3.times do
          create(:air_play, song: popular_song, radio_station:, broadcasted_at: 3.days.ago)
          create(:air_play, song: unpopular_song, radio_station:, broadcasted_at: 3.days.ago)
        end

        chart.create_chart_positions
      end

      it 'ranks the more popular song higher' do
        positions = chart.chart_positions.order(:position)
        expect(positions.first.positianable).to eq(popular_song)
        expect(positions.second.positianable).to eq(unpopular_song)
      end
    end

    context 'when weekly airplay difference outweighs popularity boost', :aggregate_failures do
      let(:chart) { create(:chart, chart_type: 'songs', date: Time.zone.today) }
      let(:popular_song) do
        create(:song, title: 'Popular But Less Played', popularity: 100, lastfm_listeners: 100_000_000,
                                                        lastfm_playcount: 1_000_000_000)
      end
      let(:heavily_played_song) do
        create(:song, title: 'Heavily Played', popularity: 0, lastfm_listeners: nil, lastfm_playcount: nil)
      end

      before do
        # Same daily count (1 play each)
        create(:air_play, song: popular_song, radio_station:, broadcasted_at: 1.day.ago)
        create(:air_play, song: heavily_played_song, radio_station:, broadcasted_at: 1.day.ago)
        # Heavily played song has much more weekly airplay
        10.times { create(:air_play, song: heavily_played_song, radio_station:, broadcasted_at: 3.days.ago) }

        chart.create_chart_positions
      end

      it 'ranks the heavily played song higher despite lower popularity' do
        positions = chart.chart_positions.order(:position)
        expect(positions.first.positianable).to eq(heavily_played_song)
        expect(positions.second.positianable).to eq(popular_song)
      end
    end

    context 'when chart type is artists' do
      let(:chart) { create(:chart, chart_type: 'artists', date: Time.zone.today) }
      let(:artist_one) { create(:artist, name: 'Artist One') }
      let(:artist_two) { create(:artist, name: 'Artist Two') }
      let(:song_one) { create(:song, title: 'Song One', artists: [artist_one]) }
      let(:song_two) { create(:song, title: 'Song Two', artists: [artist_two]) }

      before do
        # Same daily airplay count
        2.times do
          create(:air_play, song: song_one, radio_station:, broadcasted_at: 1.day.ago)
          create(:air_play, song: song_two, radio_station:, broadcasted_at: 1.day.ago)
        end
        # Artist two has more weekly plays
        5.times { create(:air_play, song: song_two, radio_station:, broadcasted_at: 3.days.ago) }

        chart.create_chart_positions
      end

      it 'ranks artist with more weekly airplay higher' do
        positions = chart.chart_positions.order(:position)
        expect(positions.first.positianable).to eq(artist_two)
      end
    end
  end

  describe '.sort_chart_items' do
    let(:radio_station) { create(:radio_station) }
    let(:start_time) { 1.week.ago }
    let(:end_time) { 1.day.ago.end_of_day.strftime('%FT%R') }

    context 'when songs have the same weekly airplay' do
      let(:popular_song) { create(:song, title: 'Popular', popularity: 80, lastfm_listeners: 10_000_000) }
      let(:unpopular_song) { create(:song, title: 'Unpopular', popularity: 10, lastfm_listeners: 100) }

      before do
        3.times do
          create(:air_play, song: popular_song, radio_station:, broadcasted_at: 2.days.ago)
          create(:air_play, song: unpopular_song, radio_station:, broadcasted_at: 2.days.ago)
        end
      end

      it 'sorts by popularity boost as tiebreaker' do
        sorted = Chart.sort_chart_items([unpopular_song, popular_song], start_time, end_time)
        expect(sorted.first).to eq(popular_song)
      end
    end

    context 'when items do not respond to popularity_boost' do
      let(:artist) { create(:artist, name: 'Test Artist') }
      let(:song) { create(:song, title: 'Test Song', artists: [artist]) }

      before do
        create(:air_play, song:, radio_station:, broadcasted_at: 2.days.ago)
      end

      it 'falls back to default boost of 1.0' do
        sorted = Chart.sort_chart_items([artist], start_time, end_time)
        expect(sorted).to eq([artist])
      end
    end
  end
end
