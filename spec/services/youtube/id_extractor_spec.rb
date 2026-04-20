# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Youtube::IdExtractor do
  describe '.extract' do
    let(:video_id) { 'ko70cExuzZM' }

    context 'with a youtu.be share link' do
      it 'returns the video id' do
        url = "https://youtu.be/#{video_id}?si=Dx7Sn9TW6LBXIv00"
        expect(described_class.extract(url)).to eq(video_id)
      end
    end

    context 'with a standard watch url' do
      it 'returns the video id' do
        url = "https://www.youtube.com/watch?v=#{video_id}&feature=share"
        expect(described_class.extract(url)).to eq(video_id)
      end
    end

    context 'with a shorts url' do
      it 'returns the video id' do
        url = "https://www.youtube.com/shorts/#{video_id}"
        expect(described_class.extract(url)).to eq(video_id)
      end
    end

    context 'with an embed url' do
      it 'returns the video id' do
        url = "https://www.youtube.com/embed/#{video_id}"
        expect(described_class.extract(url)).to eq(video_id)
      end
    end

    context 'with a bare video id' do
      it 'returns the input unchanged' do
        expect(described_class.extract(video_id)).to eq(video_id)
      end
    end

    context 'with surrounding whitespace' do
      it 'strips and extracts' do
        expect(described_class.extract("  https://youtu.be/#{video_id}  ")).to eq(video_id)
      end
    end

    context 'with a blank input' do
      it 'returns an empty string' do
        expect(described_class.extract(nil)).to eq('')
      end
    end

    context 'with an unrecognized string' do
      it 'returns the input unchanged' do
        expect(described_class.extract('not a url')).to eq('not a url')
      end
    end
  end
end
