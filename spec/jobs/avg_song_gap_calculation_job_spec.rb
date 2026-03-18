# frozen_string_literal: true

describe AvgSongGapCalculationJob do
  describe '#perform' do
    it 'calculates avg song gap for all radio stations' do
      radio_station = create(:radio_station)
      base_time = Time.current.change(min: 0)
      expected_hour = base_time.utc.hour
      create(:air_play, radio_station: radio_station, broadcasted_at: base_time - 3.minutes)
      create(:air_play, radio_station: radio_station, broadcasted_at: base_time)

      described_class.new.perform

      expect(radio_station.reload.avg_song_gap_per_hour).to include(expected_hour.to_s => 180)
    end
  end
end
