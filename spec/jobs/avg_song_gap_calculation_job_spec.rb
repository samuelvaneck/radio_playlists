# frozen_string_literal: true

describe AvgSongGapCalculationJob do
  describe '#perform' do
    it 'calculates avg song gap for all radio stations' do
      radio_station = create(:radio_station)
      now = Time.current.change(hour: 14, min: 0)
      travel_to(now) do
        create(:air_play, radio_station: radio_station, broadcasted_at: now - 3.minutes)
        create(:air_play, radio_station: radio_station, broadcasted_at: now)
      end

      described_class.new.perform

      expect(radio_station.reload.avg_song_gap_per_hour).to include('14' => 180)
    end
  end
end
