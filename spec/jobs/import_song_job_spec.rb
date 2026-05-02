# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImportSongJob do
  describe '#perform' do
    let(:radio_station) { create(:radio_station) }
    let(:job) { described_class.new }
    let(:importer) { instance_double(SongImporter, import: true) }

    before do
      allow(SongImporter).to receive(:new).with(radio_station: radio_station).and_return(importer)
      allow(ExceptionNotifier).to receive(:notify)
    end

    context 'when import completes within the timeout' do
      it 'invokes SongImporter#import and does not notify' do
        job.perform(radio_station.id)

        expect(importer).to have_received(:import)
      end

      it 'does not notify ExceptionNotifier on success' do
        job.perform(radio_station.id)

        expect(ExceptionNotifier).not_to have_received(:notify)
      end
    end

    context 'when import exceeds IMPORT_TIMEOUT_SECONDS' do
      before do
        allow(Timeout).to receive(:timeout).with(described_class::IMPORT_TIMEOUT_SECONDS).and_raise(Timeout::Error)
      end

      it 'rescues the Timeout::Error and notifies', :aggregate_failures do
        expect { job.perform(radio_station.id) }.not_to raise_error
        expect(ExceptionNotifier).to have_received(:notify).with(instance_of(Timeout::Error), 'ImportSongJob timeout')
      end
    end

    context 'when SongImporter raises an error' do
      before do
        allow(importer).to receive(:import).and_raise(StandardError, 'boom')
      end

      it 'rescues the error and notifies', :aggregate_failures do
        expect { job.perform(radio_station.id) }.not_to raise_error
        expect(ExceptionNotifier).to have_received(:notify).with(instance_of(StandardError), 'ImportSongJob')
      end
    end
  end

  describe 'sidekiq options' do
    it 'configures unique-jobs lock with TTL exceeding the wall-clock timeout', :aggregate_failures do
      options = described_class.get_sidekiq_options

      expect(options['lock']).to eq(:until_executed)
      expect(options['lock_ttl']).to be > described_class::IMPORT_TIMEOUT_SECONDS
    end
  end
end
