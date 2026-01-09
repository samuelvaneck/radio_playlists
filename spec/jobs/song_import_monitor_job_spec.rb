# frozen_string_literal: true

describe SongImportMonitorJob do
  let(:job) { described_class.new }

  describe '#perform' do
    let(:radio_station) { create(:radio_station) }

    before do
      allow(Rails.logger).to receive(:warn)
    end

    it 'runs without errors' do
      create_list(:song_import_log, 10, :with_recognition, status: :success, radio_station:)
      expect { job.perform }.not_to raise_error
    end

    it 'logs warning when failure rate exceeds 10%' do
      create_list(:song_import_log, 8, :with_recognition, status: :success, radio_station:)
      create_list(:song_import_log, 2, :with_recognition, status: :failed, radio_station:)
      job.perform
      expect(Rails.logger).to have_received(:warn).with(/High failure rate/)
    end

    it 'does not log job stats when failure rate is below 10%' do
      create_list(:song_import_log, 10, :with_recognition, status: :success, radio_station:)
      job.perform
      expect(Rails.logger).not_to have_received(:warn).with(/SongImportMonitorJob:/)
    end
  end
end
