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

  describe '#track_segments' do
    let(:segment_dir) { PersistentStream::SEGMENT_DIRECTORY.join(station_with_stream.audio_file_name) }
    let(:cache_key) { "persistent_streams:#{station_with_stream.audio_file_name}" }
    let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

    before do
      allow(Rails).to receive(:cache).and_return(memory_cache)
      allow(manager).to receive(:monitor_loop)
      allow(manager).to receive(:stop_all_processes)
      manager.start
      FileUtils.mkdir_p(segment_dir)
    end

    after do
      FileUtils.rm_rf(segment_dir)
    end

    context 'when process is alive with multiple segments' do
      before do
        process = manager.processes[station_with_stream.id]
        allow(process).to receive(:alive?).and_return(true)

        File.write(segment_dir.join('segment000.mp3'), 'oldest')
        FileUtils.touch(segment_dir.join('segment000.mp3'), mtime: 20.seconds.ago.to_time)
        File.write(segment_dir.join('segment001.mp3'), 'second newest')
        FileUtils.touch(segment_dir.join('segment001.mp3'), mtime: 10.seconds.ago.to_time)
        File.write(segment_dir.join('segment002.mp3'), 'newest - still writing')
      end

      it 'writes the second-newest segment path to Rails.cache' do
        manager.send(:track_segments)
        cached_path = Rails.cache.read(cache_key)
        expect(cached_path).to eq(segment_dir.join('segment001.mp3').to_s)
      end
    end

    context 'when process is alive with only one segment' do
      before do
        process = manager.processes[station_with_stream.id]
        allow(process).to receive(:alive?).and_return(true)

        File.write(segment_dir.join('segment000.mp3'), 'only segment')
      end

      it 'does not write to cache' do
        manager.send(:track_segments)
        expect(Rails.cache.read(cache_key)).to be_nil
      end
    end

    context 'when process is not alive' do
      before do
        process = manager.processes[station_with_stream.id]
        allow(process).to receive(:alive?).and_return(false)
      end

      it 'does not write to cache' do
        manager.send(:track_segments)
        expect(Rails.cache.read(cache_key)).to be_nil
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
