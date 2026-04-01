# frozen_string_literal: true

describe ImportSongsAllRadioStationsJob do
  describe '#perform' do
    let!(:recognizer_station) { create(:radio_station, processor: nil) }
    let!(:api_station) { create(:radio_station, processor: 'talpa_api_processor') }

    let(:recognition_setter) { instance_double(Sidekiq::Worker::Setter, perform_async: nil) }
    let(:api_setter) { instance_double(Sidekiq::Worker::Setter, perform_async: nil) }
    let(:bulk_setter) { instance_double(Sidekiq::Worker::Setter, perform_async: nil) }
    let(:job) { described_class.new }

    before do
      allow(ImportSongJob).to receive(:set).with(queue: 'recognition').and_return(recognition_setter)
      allow(ImportSongJob).to receive(:set).with(queue: 'api_scraping').and_return(api_setter)
      allow(BulkImportSongsJob).to receive(:set).with(queue: 'api_scraping').and_return(bulk_setter)
      allow(job).to receive(:sleep)
    end

    it 'enqueues recognizer-only stations on the recognition queue' do
      job.perform

      expect(recognition_setter).to have_received(:perform_async).with(recognizer_station.id)
    end

    it 'enqueues api stations on the api_scraping queue' do
      job.perform

      expect(api_setter).to have_received(:perform_async).with(api_station.id)
    end

    it 'does not enqueue api stations on the recognition queue' do
      job.perform

      expect(recognition_setter).not_to have_received(:perform_async).with(api_station.id)
    end

    it 'does not enqueue recognizer stations on the api_scraping queue' do
      job.perform

      expect(api_setter).not_to have_received(:perform_async).with(recognizer_station.id)
    end

    it 'sleeps between recognizer-only stations but not between api stations' do
      recognizer_count = RadioStation.unscoped.recognizer_only.count

      job.perform

      expect(job).to have_received(:sleep).with(2).exactly(recognizer_count).times
    end

    context 'with an interval-based station' do
      let!(:interval_station) { create(:decibel) }

      it 'enqueues BulkImportSongsJob when interval has elapsed' do
        job.perform

        expect(bulk_setter).to have_received(:perform_async).with(interval_station.id)
      end

      it 'does not enqueue BulkImportSongsJob when interval has not elapsed' do
        create(:song_import_log, radio_station: interval_station, created_at: 30.minutes.ago)

        job.perform

        expect(bulk_setter).not_to have_received(:perform_async).with(interval_station.id)
      end

      it 'does not enqueue ImportSongJob for interval-based stations' do
        job.perform

        expect(api_setter).not_to have_received(:perform_async).with(interval_station.id)
      end
    end
  end
end
