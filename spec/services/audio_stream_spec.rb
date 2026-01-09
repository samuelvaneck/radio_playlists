# frozen_string_literal: true

require 'rails_helper'

describe AudioStream, type: :service do
  let(:url) { 'http://example.com/stream.mp3' }
  let(:output_file) { '/tmp/test_output.mp3' }
  let(:audio_stream) { AudioStream::Mp3.new(url, output_file) }
  let(:stdout_content) { 'ffmpeg output' }
  let(:stderr_content) { "ICY Info: StreamTitle='Artist Name - Song Title';" }
  let(:wait_thr) { instance_double(Thread) }

  describe '#initialize' do
    it 'sets the url' do
      expect(audio_stream.url).to eq(url)
    end

    it 'sets the output_file' do
      expect(audio_stream.output_file).to eq(output_file)
    end

    it 'initializes stream_title as nil' do
      expect(audio_stream.stream_title).to be_nil
    end

    it 'initializes stream_artist as nil' do
      expect(audio_stream.stream_artist).to be_nil
    end
  end

  describe '#capture' do
    let(:stdin) { instance_double(IO) }
    let(:stdout) { instance_double(IO, read: stdout_content) }
    let(:stderr) { instance_double(IO, read: stderr_content) }

    before do
      allow(Rails.logger).to receive(:debug)
      allow(Rails.logger).to receive(:error)
    end

    context 'when stream metadata is successfully captured' do
      let(:detection) { { encoding: 'ISO-8859-1' } }
      let(:utf8_content) { "ICY Info: StreamTitle='Artist Name - Song Title';" }

      before do
        allow(Open3).to receive(:popen3).and_yield(stdin, stdout, stderr, wait_thr)
        allow(CharlockHolmes::EncodingDetector).to receive(:detect).with(stderr_content).and_return(detection)
        allow(CharlockHolmes::Converter).to receive(:convert)
          .with(stderr_content, 'ISO-8859-1', 'UTF-8')
          .and_return(utf8_content)
      end

      it 'logs the capture command' do
        audio_stream.capture
        expect(Rails.logger).to have_received(:debug).with(/Capturing stream command/)
      end

      it 'executes the ffmpeg command' do
        audio_stream.capture
        expect(Open3).to have_received(:popen3)
      end

      it 'sets the stream_artist' do
        audio_stream.capture
        expect(audio_stream.stream_artist).to eq('Artist Name')
      end

      it 'sets the stream_title' do
        audio_stream.capture
        expect(audio_stream.stream_title).to eq('Song Title')
      end

      it 'converts stderr to UTF-8' do
        audio_stream.capture
        expect(CharlockHolmes::Converter).to have_received(:convert)
          .with(stderr_content, 'ISO-8859-1', 'UTF-8')
      end
    end

    context 'when stream metadata has extra whitespace' do
      let(:detection) { { encoding: 'UTF-8' } }
      let(:utf8_content) { "ICY Info: StreamTitle='  Artist Name  -  Song Title  ';" }

      before do
        allow(Open3).to receive(:popen3).and_yield(stdin, stdout, stderr, wait_thr)
        allow(CharlockHolmes::EncodingDetector).to receive(:detect).and_return(detection)
        allow(CharlockHolmes::Converter).to receive(:convert).and_return(utf8_content)
      end

      it 'strips whitespace from stream_artist' do
        audio_stream.capture
        expect(audio_stream.stream_artist).to eq('Artist Name')
      end

      it 'strips whitespace from stream_title' do
        audio_stream.capture
        expect(audio_stream.stream_title).to eq('Song Title')
      end
    end

    context 'when no StreamTitle is found in stderr' do
      let(:stderr_content) { 'ffmpeg error output without StreamTitle' }
      let(:detection) { { encoding: 'UTF-8' } }

      before do
        allow(Open3).to receive(:popen3).and_yield(stdin, stdout, stderr, wait_thr)
        allow(CharlockHolmes::EncodingDetector).to receive(:detect).and_return(detection)
        allow(CharlockHolmes::Converter).to receive(:convert).and_return(stderr_content)
      end

      it 'does not set stream_artist' do
        audio_stream.capture
        expect(audio_stream.stream_artist).to be_nil
      end

      it 'does not set stream_title' do
        audio_stream.capture
        expect(audio_stream.stream_title).to be_nil
      end
    end

    context 'when convert_stderr_to_utf8 returns blank' do
      before do
        allow(Open3).to receive(:popen3).and_yield(stdin, stdout, stderr, wait_thr)
        allow(audio_stream).to receive(:convert_stderr_to_utf8).and_return('')
      end

      it 'does not set stream_artist' do
        audio_stream.capture
        expect(audio_stream.stream_artist).to be_nil
      end

      it 'does not set stream_title' do
        audio_stream.capture
        expect(audio_stream.stream_title).to be_nil
      end
    end

    context 'when an error occurs during capture' do
      before do
        allow(Open3).to receive(:popen3).and_raise(StandardError.new('Connection failed'))
      end

      it 'logs the error' do
        audio_stream.capture
        expect(Rails.logger).to have_received(:error).with(/Error capturing stream for url/)
      end

      it 'sets stream_artist to nil' do
        audio_stream.capture
        expect(audio_stream.stream_artist).to be_nil
      end

      it 'sets stream_title to nil' do
        audio_stream.capture
        expect(audio_stream.stream_title).to be_nil
      end

      it 'does not raise the error' do
        expect { audio_stream.capture }.not_to raise_error
      end
    end
  end

  describe '#delete_file' do
    context 'when the file exists' do
      before do
        allow(File).to receive(:exist?).with(output_file).and_return(true)
        allow(File).to receive(:delete).with(output_file)
      end

      it 'deletes the file' do
        audio_stream.delete_file
        expect(File).to have_received(:delete).with(output_file)
      end
    end

    context 'when the file does not exist' do
      before do
        allow(File).to receive(:exist?).with(output_file).and_return(false)
        allow(File).to receive(:delete)
      end

      it 'does not attempt to delete the file' do
        audio_stream.delete_file
        expect(File).not_to have_received(:delete)
      end
    end
  end

  describe '#convert_stderr_to_utf8' do
    let(:stderr_content) { "Some content\nStreamTitle='Test';\nMore content" }
    let(:detection) { { encoding: 'ISO-8859-1' } }
    let(:utf8_content) { "Some content\nStreamTitle='Test';\nMore content" }

    before do
      audio_stream.instance_variable_set(:@stderr, stderr_content)
      allow(CharlockHolmes::EncodingDetector).to receive(:detect).with(stderr_content).and_return(detection)
      allow(CharlockHolmes::Converter).to receive(:convert)
        .with(stderr_content, 'ISO-8859-1', 'UTF-8')
        .and_return(utf8_content)
    end

    it 'detects the encoding of stderr' do
      audio_stream.convert_stderr_to_utf8
      expect(CharlockHolmes::EncodingDetector).to have_received(:detect).with(stderr_content)
    end

    it 'converts stderr to UTF-8' do
      audio_stream.convert_stderr_to_utf8
      expect(CharlockHolmes::Converter).to have_received(:convert)
        .with(stderr_content, 'ISO-8859-1', 'UTF-8')
    end

    it 'returns the line containing StreamTitle' do
      result = audio_stream.convert_stderr_to_utf8
      expect(result).to eq("StreamTitle='Test';")
    end

    context 'when there is no StreamTitle in stderr' do
      let(:stderr_content) { "Some content\nMore content" }
      let(:utf8_content) { "Some content\nMore content" }

      it 'returns nil' do
        result = audio_stream.convert_stderr_to_utf8
        expect(result).to be_nil
      end
    end
  end
end
