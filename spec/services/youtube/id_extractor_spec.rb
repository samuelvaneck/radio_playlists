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
      it 'returns an empty string for nil' do
        expect(described_class.extract(nil)).to eq('')
      end

      it 'returns an empty string for an empty string' do
        expect(described_class.extract('')).to eq('')
      end

      it 'returns an empty string for whitespace' do
        expect(described_class.extract("   \n")).to eq('')
      end
    end

    context 'with an unrecognized string' do
      it 'returns the input unchanged' do
        expect(described_class.extract('not a url')).to eq('not a url')
      end

      it 'returns a non-youtube url unchanged' do
        expect(described_class.extract('https://vimeo.com/123456789')).to eq('https://vimeo.com/123456789')
      end
    end

    context 'with a mobile youtube url' do
      it 'returns the video id' do
        url = "https://m.youtube.com/watch?v=#{video_id}"
        expect(described_class.extract(url)).to eq(video_id)
      end
    end

    context 'with a youtube music url' do
      it 'returns the video id' do
        url = "https://music.youtube.com/watch?v=#{video_id}&list=RDAMVM#{video_id}"
        expect(described_class.extract(url)).to eq(video_id)
      end
    end

    context 'with an http (non-https) url' do
      it 'returns the video id' do
        url = "http://youtu.be/#{video_id}"
        expect(described_class.extract(url)).to eq(video_id)
      end
    end

    context 'with a watch url where v= is not the first parameter' do
      it 'returns the video id' do
        url = "https://www.youtube.com/watch?list=PLabc123&v=#{video_id}&index=4"
        expect(described_class.extract(url)).to eq(video_id)
      end
    end

    context 'with a watch url containing a timestamp after the id' do
      it 'returns the video id' do
        url = "https://www.youtube.com/watch?v=#{video_id}&t=30s"
        expect(described_class.extract(url)).to eq(video_id)
      end
    end

    context 'with a youtu.be link containing a timestamp' do
      it 'returns the video id' do
        url = "https://youtu.be/#{video_id}?t=42"
        expect(described_class.extract(url)).to eq(video_id)
      end
    end

    context 'with an id containing hyphens and underscores' do
      let(:video_id) { 'a_b-C1D2E3F' }

      it 'returns the full id' do
        expect(described_class.extract("https://youtu.be/#{video_id}")).to eq(video_id)
      end
    end

    context 'with a youtu.be url that has no id' do
      it 'returns the input unchanged' do
        expect(described_class.extract('https://youtu.be/')).to eq('https://youtu.be/')
      end
    end
  end
end
