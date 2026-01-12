# frozen_string_literal: true

require 'rails_helper'

RSpec.describe YoutubeAudioDownloader, type: :service do
  let(:youtube_id) { 'dQw4w9WgXcQ' }
  let(:downloader) { described_class.new(youtube_id) }

  describe '#download' do
    context 'when youtube_id is blank' do
      let(:youtube_id) { nil }

      it 'raises a DownloadError' do
        expect { downloader.download }.to raise_error(described_class::DownloadError, /YouTube ID is required/)
      end
    end

    context 'when youtube_id has invalid format' do
      let(:youtube_id) { 'invalid' }

      it 'raises a DownloadError' do
        expect { downloader.download }.to raise_error(described_class::DownloadError, /Invalid YouTube ID format/)
      end
    end

    context 'when yt-dlp fails' do
      before do
        allow(Open3).to receive(:capture3)
          .and_return(['', 'ERROR: Video unavailable', instance_double(Process::Status, success?: false)])
      end

      it 'raises a DownloadError' do
        expect { downloader.download }.to raise_error(described_class::DownloadError, /yt-dlp failed/)
      end
    end

    context 'when yt-dlp succeeds' do
      let(:json_output) do
        { 'duration' => 212, 'title' => 'Rick Astley - Never Gonna Give You Up' }.to_json
      end
      let(:expected_output_file) { Rails.root.join('tmp', 'audio', "youtube_#{youtube_id}_#{Time.current.to_i}.mp3").to_s }

      before do
        allow(Open3).to receive(:capture3)
          .and_return([json_output, '', instance_double(Process::Status, success?: true)])
      end

      it 'returns download result with output_file', :aggregate_failures do
        result = downloader.download
        expect(result[:output_file]).to match(%r{tmp/audio/youtube_#{youtube_id}_\d+\.mp3})
      end

      it 'returns download result with duration' do
        result = downloader.download
        expect(result[:duration]).to eq(212)
      end

      it 'sets the output_file attribute' do
        downloader.download
        expect(downloader.output_file).to match(%r{tmp/audio/youtube_#{youtube_id}})
      end

      it 'sets the duration attribute' do
        downloader.download
        expect(downloader.duration).to eq(212)
      end
    end

    context 'when yt-dlp output is not valid JSON' do
      before do
        allow(Open3).to receive(:capture3)
          .and_return(['not json', '', instance_double(Process::Status, success?: true)])
      end

      it 'does not raise an error' do
        expect { downloader.download }.not_to raise_error
      end

      it 'sets duration to nil' do
        downloader.download
        expect(downloader.duration).to be_nil
      end
    end
  end

  describe '#cleanup' do
    let(:output_file) { '/tmp/test_audio.mp3' }

    before do
      downloader.instance_variable_set(:@output_file, output_file)
    end

    context 'when output file exists' do
      before do
        allow(File).to receive(:exist?).with(output_file).and_return(true)
        allow(File).to receive(:delete).with(output_file)
      end

      it 'deletes the file' do
        downloader.cleanup
        expect(File).to have_received(:delete).with(output_file)
      end
    end

    context 'when output file does not exist' do
      before do
        allow(File).to receive(:exist?).with(output_file).and_return(false)
      end

      it 'does not attempt to delete' do
        allow(File).to receive(:delete)
        downloader.cleanup
        expect(File).not_to have_received(:delete)
      end
    end

    context 'when output_file is nil' do
      before do
        downloader.instance_variable_set(:@output_file, nil)
      end

      it 'does not raise an error' do
        expect { downloader.cleanup }.not_to raise_error
      end
    end
  end
end
