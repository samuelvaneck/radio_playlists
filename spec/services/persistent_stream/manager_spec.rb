# frozen_string_literal: true

require 'rails_helper'

describe PersistentStream::Manager, type: :service do
  let(:manager) { described_class.new }

  let!(:station_with_stream) do
    create(:radio_station, name: 'Stream FM', direct_stream_url: 'https://stream.example.com/test.mp3')
  end

  before do
    create(:radio_station, name: 'No Stream FM', direct_stream_url: nil)
    allow(::Process).to receive(:spawn).and_return(12_345)
    allow(::Process).to receive(:detach)
  end

  describe '#start' do
    it 'starts processes only for stations with direct_stream_url' do
      allow(manager).to receive(:monitor_loop)
      allow(manager).to receive(:stop_all_processes)
      manager.start
      expect(manager.processes.keys).to eq([station_with_stream.id])
    end
  end

  describe '#stop' do
    it 'sets running to false' do
      manager.stop
      expect(manager.instance_variable_get(:@running)).to be false
    end
  end

  describe '#status' do
    before do
      allow(manager).to receive(:monitor_loop)
      allow(manager).to receive(:stop_all_processes)
      manager.start
    end

    context 'when process is alive and segments are fresh' do
      before do
        process = manager.processes[station_with_stream.id]
        allow(process).to receive(:alive?).and_return(true)

        reader = instance_double(PersistentStream::SegmentReader, available?: true)
        allow(PersistentStream::SegmentReader).to receive(:new).and_return(reader)
      end

      it 'reports ACTIVE status', :aggregate_failures do
        result = manager.status.first
        expect(result[:name]).to eq('Stream FM')
        expect(result[:state]).to eq('ACTIVE')
      end
    end

    context 'when process is alive but segments are stale' do
      before do
        process = manager.processes[station_with_stream.id]
        allow(process).to receive(:alive?).and_return(true)

        reader = instance_double(PersistentStream::SegmentReader, available?: false)
        allow(PersistentStream::SegmentReader).to receive(:new).and_return(reader)
      end

      it 'reports STALE status' do
        result = manager.status.first
        expect(result[:state]).to eq('STALE')
      end
    end

    context 'when process is not alive' do
      before do
        process = manager.processes[station_with_stream.id]
        allow(process).to receive(:alive?).and_return(false)
      end

      it 'reports NOT RUNNING status' do
        result = manager.status.first
        expect(result[:state]).to eq('NOT RUNNING')
      end
    end
  end

  describe 'health checking' do
    before do
      allow(manager).to receive(:monitor_loop)
      allow(manager).to receive(:stop_all_processes)
      manager.start
    end

    context 'when a process has died' do
      it 'restarts the dead process' do
        process = manager.processes[station_with_stream.id]
        allow(process).to receive(:alive?).and_return(false)
        allow(process).to receive(:restart)

        manager.send(:check_health)

        expect(process).to have_received(:restart)
      end
    end

    context 'when all processes are alive' do
      it 'does not restart any processes' do
        process = manager.processes[station_with_stream.id]
        allow(process).to receive(:alive?).and_return(true)
        allow(process).to receive(:restart)

        manager.send(:check_health)

        expect(process).not_to have_received(:restart)
      end
    end
  end
end
