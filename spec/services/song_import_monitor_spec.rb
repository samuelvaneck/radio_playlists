# frozen_string_literal: true

describe SongImportMonitor do
  let(:monitor) { described_class.new(time_window: 1.hour) }
  let(:radio_station) { create(:radio_station) }

  describe '#check_failure_rate' do
    context 'when there are not enough samples' do
      before do
        create_list(:song_import_log, 5, :with_recognition, radio_station:)
      end

      it 'returns nil' do
        expect(monitor.check_failure_rate).to be_nil
      end
    end

    context 'when failure rate is below threshold' do
      before do
        create_list(:song_import_log, 8, :with_recognition, status: :success, radio_station:)
        create_list(:song_import_log, 2, :failed, radio_station:)
        allow(Rails.logger).to receive(:warn)
      end

      it 'does not log warning' do
        monitor.check_failure_rate
        expect(Rails.logger).not_to have_received(:warn)
      end

      it 'returns correct failure rate' do
        stats = monitor.check_failure_rate
        expect(stats[:failure_rate]).to eq(0.2)
      end
    end

    context 'when failure rate exceeds threshold' do
      before do
        create_list(:song_import_log, 5, :with_recognition, status: :success, radio_station:)
        create_list(:song_import_log, 5, :failed, radio_station:)
        allow(Rails.logger).to receive(:warn)
      end

      it 'logs a warning' do
        monitor.check_failure_rate
        expect(Rails.logger).to have_received(:warn).with(/High failure rate detected/)
      end

      it 'returns correct failure rate' do
        stats = monitor.check_failure_rate
        expect(stats[:failure_rate]).to eq(0.5)
      end

      it 'returns correct total count' do
        stats = monitor.check_failure_rate
        expect(stats[:total]).to eq(10)
      end

      it 'returns correct failed count' do
        stats = monitor.check_failure_rate
        expect(stats[:failed]).to eq(5)
      end
    end

    context 'when logs are older than time window' do
      before do
        create_list(:song_import_log, 10, :failed, radio_station:, created_at: 2.hours.ago)
      end

      it 'does not count old logs' do
        expect(monitor.check_failure_rate).to be_nil
      end
    end
  end

  describe '#check_failure_rate_by_station' do
    let(:healthy_station) { create(:radio_station, name: 'Healthy Station') }
    let(:failing_station) { create(:radio_station, name: 'Failing Station') }

    context 'when one station has high failure rate' do
      before do
        create_list(:song_import_log, 10, :with_recognition, status: :success, radio_station: healthy_station)
        create_list(:song_import_log, 5, :with_recognition, status: :success, radio_station: failing_station)
        create_list(:song_import_log, 5, :failed, radio_station: failing_station)
        allow(Rails.logger).to receive(:warn)
      end

      it 'logs warning for the failing station' do
        monitor.check_failure_rate_by_station
        expect(Rails.logger).to have_received(:warn).with(/High failure rate for Failing Station/)
      end

      it 'does not log warning for healthy station' do
        monitor.check_failure_rate_by_station
        expect(Rails.logger).not_to have_received(:warn).with(/Healthy Station/)
      end
    end
  end
end
