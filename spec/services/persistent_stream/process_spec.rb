# frozen_string_literal: true

require 'rails_helper'

describe PersistentStream::Process, type: :service do
  let(:radio_station) { create(:radio_station, name: 'Test FM', direct_stream_url: 'https://stream.example.com/test.mp3') }
  let(:process_instance) { described_class.new(radio_station) }

  describe '#initialize' do
    it 'sets the radio_station' do
      expect(process_instance.radio_station).to eq(radio_station)
    end

    it 'sets pid to nil' do
      expect(process_instance.pid).to be_nil
    end
  end

  describe '#segment_directory' do
    it 'returns a path based on the station audio_file_name' do
      expected = Rails.root.join('tmp/audio/persistent', radio_station.audio_file_name)
      expect(process_instance.segment_directory).to eq(expected)
    end
  end

  describe '#start' do
    let(:spawn_args) { [] }

    before do
      allow(::Process).to receive(:spawn) do |*args|
        spawn_args.replace(args)
        12_345
      end
      allow(::Process).to receive(:detach)
    end

    it 'spawns an ffmpeg process and stores pid', :aggregate_failures do
      process_instance.start
      expect(::Process).to have_received(:spawn)
      expect(process_instance.pid).to eq(12_345)
    end

    it 'detaches the spawned process' do
      process_instance.start
      expect(::Process).to have_received(:detach).with(12_345)
    end

    it 'includes reconnect options in the ffmpeg command' do
      process_instance.start
      expect(spawn_args).to include('-reconnect', '1', '-reconnect_streamed', '1')
    end

    it 'includes segment muxer options in the ffmpeg command' do
      process_instance.start
      expect(spawn_args).to include('-f', 'segment', '-segment_time', '10')
    end

    it 'does not include segment_list options in the ffmpeg command', :aggregate_failures do
      process_instance.start
      expect(spawn_args).not_to include('-segment_list')
      expect(spawn_args).not_to include('-segment_list_type')
    end

    context 'when stream is MP3' do
      it 'uses copy codec' do
        process_instance.start
        expect(spawn_args).to include('-c', 'copy')
      end
    end

    context 'when stream is M3U8' do
      let(:radio_station) { create(:radio_station, name: 'HLS FM', direct_stream_url: 'https://stream.example.com/test.m3u8') }

      it 'uses libmp3lame codec' do
        process_instance.start
        expect(spawn_args).to include('-codec:a', 'libmp3lame')
      end
    end
  end

  describe '#stop' do
    before do
      allow(::Process).to receive(:spawn).and_return(12_345)
      allow(::Process).to receive(:detach)
      process_instance.start
    end

    it 'sends SIGTERM to the process and clears pid', :aggregate_failures do
      allow(::Process).to receive(:kill).and_raise(Errno::ESRCH)
      process_instance.stop
      expect(::Process).to have_received(:kill).with('TERM', 12_345)
      expect(process_instance.pid).to be_nil
    end

    context 'when process is already gone' do
      it 'handles ESRCH gracefully' do
        allow(::Process).to receive(:kill).and_raise(Errno::ESRCH)
        expect { process_instance.stop }.not_to raise_error
      end
    end
  end

  describe '#alive?' do
    context 'when pid is nil' do
      it 'returns false' do
        expect(process_instance.alive?).to be false
      end
    end

    context 'when process is running' do
      before do
        allow(::Process).to receive(:spawn).and_return(12_345)
        allow(::Process).to receive(:detach)
        process_instance.start
        allow(::Process).to receive(:kill).with(0, 12_345).and_return(1)
      end

      it 'returns true' do
        expect(process_instance.alive?).to be true
      end
    end

    context 'when process is dead' do
      before do
        allow(::Process).to receive(:spawn).and_return(12_345)
        allow(::Process).to receive(:detach)
        process_instance.start
        allow(::Process).to receive(:kill).with(0, 12_345).and_raise(Errno::ESRCH)
      end

      it 'returns false' do
        expect(process_instance.alive?).to be false
      end
    end
  end

  describe '#restart' do
    before do
      allow(::Process).to receive(:spawn).and_return(12_345, 67_890)
      allow(::Process).to receive(:detach)
      allow(::Process).to receive(:kill).and_raise(Errno::ESRCH)
      process_instance.start
    end

    it 'stops and restarts with a new pid' do
      process_instance.restart
      expect(process_instance.pid).to eq(67_890)
    end
  end
end
