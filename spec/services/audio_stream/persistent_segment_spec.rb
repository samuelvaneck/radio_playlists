# frozen_string_literal: true

require 'rails_helper'

describe AudioStream::PersistentSegment, type: :service do
  let(:radio_station) { create(:radio_station, name: 'Test FM', direct_stream_url: 'https://stream.example.com/test.mp3') }
  let(:output_file) { Rails.root.join('tmp/test_persistent_segment.mp3') }
  let(:audio_stream) { described_class.new(radio_station, output_file) }

  after { FileUtils.rm_f(output_file) }

  describe '#initialize' do
    it 'sets the url from radio_station direct_stream_url' do
      expect(audio_stream.url).to eq('https://stream.example.com/test.mp3')
    end

    it 'sets the output_file' do
      expect(audio_stream.output_file).to eq(output_file)
    end
  end

  describe '#capture' do
    let(:segment_reader) { instance_double(PersistentStream::SegmentReader) }

    before do
      allow(PersistentStream::SegmentReader).to receive(:new).with(radio_station).and_return(segment_reader)
    end

    context 'when a segment is available' do
      before do
        allow(segment_reader).to receive(:read_latest).with(output_file).and_return(output_file)
      end

      it 'delegates to SegmentReader#read_latest' do
        described_class.new(radio_station, output_file).capture
        expect(segment_reader).to have_received(:read_latest).with(output_file)
      end
    end

    context 'when no segment is available' do
      before do
        allow(segment_reader).to receive(:read_latest).and_raise(PersistentStream::SegmentReader::NoSegmentError, 'No segments')
      end

      it 'handles the error gracefully' do
        expect { described_class.new(radio_station, output_file).capture }.not_to raise_error
      end
    end

    context 'when segment is stale' do
      before do
        allow(segment_reader).to receive(:read_latest).and_raise(PersistentStream::SegmentReader::StaleSegmentError, 'Stale segment')
      end

      it 'handles the error gracefully' do
        expect { described_class.new(radio_station, output_file).capture }.not_to raise_error
      end
    end
  end

  describe '#delete_file' do
    it 'deletes the output file' do
      File.write(output_file, 'test data')
      audio_stream.delete_file
      expect(File.exist?(output_file)).to be false
    end

    it 'does not raise if file does not exist' do
      expect { audio_stream.delete_file }.not_to raise_error
    end
  end
end
