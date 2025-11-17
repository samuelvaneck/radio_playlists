# frozen_string_literal: true

require 'rails_helper'

describe AudioStream::M3u8, type: :service do
  let(:url) { 'http://example.com/stream.m3u8' }
  let(:output_file) { '/tmp/test_output.mp3' }
  let(:audio_stream) { described_class.new(url, output_file) }

  describe '#initialize' do
    it 'sets the url' do
      expect(audio_stream.url).to eq(url)
    end

    it 'sets the output_file' do
      expect(audio_stream.output_file).to eq(output_file)
    end

    it 'sets the command with ffmpeg m3u8 conversion command' do
      expected_command = ["ffmpeg -y -t 00:00:05 -i #{url} -codec:a libmp3lame #{output_file}"]
      expect(audio_stream.command).to eq(expected_command)
    end
  end
end
