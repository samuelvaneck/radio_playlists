# frozen_string_literal: true

require 'rails_helper'

describe PersistentStream::SegmentReader, type: :service do
  let(:radio_station) { create(:radio_station, name: 'Test FM', direct_stream_url: 'https://stream.example.com/test.mp3') }
  let(:reader) { described_class.new(radio_station) }
  let(:segment_dir) { PersistentStream::SEGMENT_DIRECTORY.join(radio_station.audio_file_name) }
  let(:segment_list) { segment_dir.join('segments.csv') }

  before do
    FileUtils.mkdir_p(segment_dir)
  end

  after do
    FileUtils.rm_rf(segment_dir)
  end

  describe '#available?' do
    context 'when no segment list exists' do
      it 'returns false' do
        expect(reader.available?).to be false
      end
    end

    context 'when segment list is empty' do
      before { File.write(segment_list, '') }

      it 'returns false' do
        expect(reader.available?).to be false
      end
    end

    context 'when segment file does not exist on disk' do
      before { File.write(segment_list, "segment000.mp3,0.0,10.0\n") }

      it 'returns false' do
        expect(reader.available?).to be false
      end
    end

    context 'when segment file exists but is stale' do
      let(:segment_file) { segment_dir.join('segment000.mp3') }

      before do
        File.write(segment_list, "segment000.mp3,0.0,10.0\n")
        File.write(segment_file, 'audio data')
        FileUtils.touch(segment_file, mtime: 60.seconds.ago.to_time)
      end

      it 'returns false' do
        expect(reader.available?).to be false
      end
    end

    context 'when a fresh segment exists' do
      let(:segment_file) { segment_dir.join('segment000.mp3') }

      before do
        File.write(segment_list, "segment000.mp3,0.0,10.0\n")
        File.write(segment_file, 'audio data')
      end

      it 'returns true' do
        expect(reader.available?).to be true
      end
    end
  end

  describe '#read_latest' do
    let(:output_file) { Rails.root.join('tmp/test_segment_output.mp3') }

    after { FileUtils.rm_f(output_file) }

    context 'when no segments are available' do
      it 'raises NoSegmentError' do
        expect { reader.read_latest(output_file) }.to raise_error(PersistentStream::SegmentReader::NoSegmentError)
      end
    end

    context 'when a fresh segment exists' do
      let(:segment_file) { segment_dir.join('segment001.mp3') }

      before do
        File.write(segment_list, "segment000.mp3,0.0,10.0\nsegment001.mp3,10.0,20.0\n")
        File.write(segment_dir.join('segment000.mp3'), 'old audio')
        File.write(segment_file, 'latest audio data')
      end

      it 'copies the latest segment to the output file', :aggregate_failures do
        reader.read_latest(output_file)
        expect(File.exist?(output_file)).to be true
        expect(File.read(output_file)).to eq('latest audio data')
      end

      it 'returns the output file path' do
        expect(reader.read_latest(output_file)).to eq(output_file)
      end
    end

    context 'when segment list has absolute paths' do
      let(:segment_file) { segment_dir.join('segment000.mp3') }

      before do
        File.write(segment_list, "#{segment_file},0.0,10.0\n")
        File.write(segment_file, 'absolute path audio')
      end

      it 'reads the segment using the absolute path' do
        reader.read_latest(output_file)
        expect(File.read(output_file)).to eq('absolute path audio')
      end
    end
  end
end
