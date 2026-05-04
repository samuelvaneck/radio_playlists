# frozen_string_literal: true

describe ImportSongsAllRadioStationsJob do
  describe '#perform' do
    let!(:recognizer_station) { create(:radio_station, processor: nil) }
    let!(:api_station) { create(:radio_station, processor: 'talpa_api_processor') }

    let(:job) { described_class.new }

    before do
      allow(ImportSongJob).to receive(:perform_async)
      allow(job).to receive(:sleep)
    end

    it 'enqueues recognizer-only stations' do
      job.perform

      expect(ImportSongJob).to have_received(:perform_async).with(recognizer_station.id)
    end

    it 'enqueues api stations' do
      job.perform

      expect(ImportSongJob).to have_received(:perform_async).with(api_station.id)
    end

    it 'sleeps between recognizer-only stations but not between api stations' do
      recognizer_count = RadioStation.unscoped.recognizer_only.count

      job.perform

      expect(job).to have_received(:sleep).with(2).exactly(recognizer_count).times
    end
  end
end
