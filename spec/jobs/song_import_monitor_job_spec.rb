# frozen_string_literal: true

describe SongImportMonitorJob do
  let(:job) { described_class.new }

  describe '#perform' do
    let(:radio_station) { create(:radio_station) }

    before do
      create_list(:song_import_log, 10, :with_recognition, status: :success, radio_station:)
      allow(Rails.logger).to receive(:info)
    end

    it 'runs without errors' do
      expect { job.perform }.not_to raise_error
    end

    it 'logs stats when there are enough samples' do
      job.perform
      expect(Rails.logger).to have_received(:info).with(/Last hour stats/)
    end
  end
end
