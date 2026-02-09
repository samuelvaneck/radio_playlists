# frozen_string_literal: true

require 'rails_helper'

describe PersistentStream::SegmentReader, type: :service do
  let(:radio_station) { create(:radio_station, name: 'Test FM', direct_stream_url: 'https://stream.example.com/test.mp3') }
  let(:reader) { described_class.new(radio_station) }
  let(:segment_dir) { PersistentStream::SEGMENT_DIRECTORY.join(radio_station.audio_file_name) }
  let(:cache_key) { "persistent_streams:#{radio_station.audio_file_name}" }

  before do
    FileUtils.mkdir_p(segment_dir)
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
  end

  after do
    FileUtils.rm_rf(segment_dir)
  end

  describe '#available?' do
    context 'when no Redis key exists' do
      before { Rails.cache.delete(cache_key) }

      it 'returns false' do
        expect(reader.available?).to be false
      end
    end

    context 'when Redis key points to a nonexistent file' do
      before { Rails.cache.write(cache_key, segment_dir.join('segment000.mp3').to_s) }

      it 'returns false' do
        expect(reader.available?).to be false
      end
    end

    context 'when Redis key points to an existing file' do
      let(:segment_file) { segment_dir.join('segment000.mp3') }

      before do
        File.write(segment_file, 'audio data')
        Rails.cache.write(cache_key, segment_file.to_s)
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
      before { Rails.cache.delete(cache_key) }

      it 'raises NoSegmentError' do
        expect { reader.read_latest(output_file) }.to raise_error(PersistentStream::SegmentReader::NoSegmentError)
      end
    end

    context 'when a segment exists in Redis' do
      let(:segment_file) { segment_dir.join('segment001.mp3') }

      before do
        File.write(segment_file, 'latest audio data')
        Rails.cache.write(cache_key, segment_file.to_s)
      end

      it 'copies the segment to the output file', :aggregate_failures do
        reader.read_latest(output_file)
        expect(File.exist?(output_file)).to be true
        expect(File.read(output_file)).to eq('latest audio data')
      end

      it 'returns the output file path' do
        expect(reader.read_latest(output_file)).to eq(output_file)
      end
    end
  end
end
