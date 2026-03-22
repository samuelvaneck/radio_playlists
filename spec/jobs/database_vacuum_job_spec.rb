# frozen_string_literal: true

describe DatabaseVacuumJob do
  let(:job) { described_class.new }
  let(:pg_connection) { instance_double(PG::Connection) }

  before do
    allow(ActiveRecord::Base.connection).to receive(:raw_connection).and_return(pg_connection)
  end

  describe '#perform' do
    it 'executes VACUUM ANALYZE on all configured tables' do
      allow(pg_connection).to receive(:exec)

      described_class::TABLES.each do |table|
        expect(pg_connection).to receive(:exec).with("VACUUM ANALYZE #{table}")
      end

      job.perform
    end

    context 'when a table vacuum fails' do
      before do
        allow(pg_connection).to receive(:exec).and_raise(StandardError, 'shm full')
      end

      it 'continues vacuuming remaining tables', :aggregate_failures do
        expect { job.perform }.not_to raise_error
        expect(pg_connection).to have_received(:exec).exactly(described_class::TABLES.size).times
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)

        job.perform

        expect(Rails.logger).to have_received(:error).with(/air_plays failed: shm full/).at_least(:once)
      end
    end
  end
end
