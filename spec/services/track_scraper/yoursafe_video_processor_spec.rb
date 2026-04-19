# frozen_string_literal: true

require 'rails_helper'

describe TrackScraper::YoursafeVideoProcessor, type: :service do
  describe '#last_played_song' do
    subject(:last_played_song) { processor.last_played_song }

    let(:processor) { described_class.new(radio_station) }
    let(:radio_station) do
      RadioStation.find_by(name: 'Yoursafe Radio').presence || create(:yoursafe_radio)
    end
    let(:frame_file) { Rails.root.join('tmp/audio/yoursafe_frame_test.png').to_s }

    before do
      allow(processor).to receive(:extract_video_frame).and_return(frame_result)
      allow(File).to receive(:delete).and_call_original
      allow(File).to receive(:delete).with(frame_file).and_return(1)
      allow(File).to receive(:exist?).and_call_original
    end

    context 'when the video frame contains a valid artist and title' do
      let(:frame_result) { frame_file }
      let(:ocr_text) { "@ yoursafe\n——radio\n\nJE LUISTERT NAAR\n\nTom Odell - Another Love (Radio Edit)\n" }

      before do
        allow(File).to receive(:exist?).with(frame_file).and_return(true)
        rtesseract_instance = instance_double(RTesseract, to_s: ocr_text)
        allow(RTesseract).to receive(:new).with(frame_file, lang: described_class::OCR_LANGUAGES).and_return(rtesseract_instance)
      end

      it 'sets the artist name' do
        last_played_song
        expect(processor.artist_name).to eq('Tom Odell')
      end

      it 'sets the title' do
        last_played_song
        expect(processor.title).to eq('Another Love (Radio Edit)')
      end

      it 'sets the broadcasted_at timestamp' do
        last_played_song
        expect(processor.instance_variable_get(:@broadcasted_at)).to be_within(1.second).of(Time.zone.now)
      end

      it 'returns true' do
        expect(last_played_song).to be true
      end

      it 'cleans up the frame file' do
        last_played_song
        expect(File).to have_received(:delete).with(frame_file)
      end
    end

    context 'when the artist contains multiple artists' do
      let(:frame_result) { frame_file }
      let(:ocr_text) { "JE LUISTERT NAAR\n\nThe Chainsmokers & Coldplay - Something Just Like This\n" }

      before do
        allow(File).to receive(:exist?).with(frame_file).and_return(true)
        rtesseract_instance = instance_double(RTesseract, to_s: ocr_text)
        allow(RTesseract).to receive(:new).with(frame_file, lang: described_class::OCR_LANGUAGES).and_return(rtesseract_instance)
      end

      it 'sets the full artist string' do
        last_played_song
        expect(processor.artist_name).to eq('The Chainsmokers & Coldplay')
      end

      it 'sets the title' do
        last_played_song
        expect(processor.title).to eq('Something Just Like This')
      end
    end

    context 'when the video frame extraction fails' do
      let(:frame_result) { nil }

      it 'returns false' do
        expect(last_played_song).to be false
      end
    end

    context 'when OCR returns blank text' do
      let(:frame_result) { frame_file }

      before do
        allow(File).to receive(:exist?).with(frame_file).and_return(true)
        rtesseract_instance = instance_double(RTesseract, to_s: '')
        allow(RTesseract).to receive(:new).with(frame_file, lang: described_class::OCR_LANGUAGES).and_return(rtesseract_instance)
      end

      it 'returns false' do
        expect(last_played_song).to be false
      end
    end

    context 'when OCR text has no artist-title separator' do
      let(:frame_result) { frame_file }
      let(:ocr_text) { "@ yoursafe\n——radio\n\nJE LUISTERT NAAR\n\nSome text without separator\n" }

      before do
        allow(File).to receive(:exist?).with(frame_file).and_return(true)
        rtesseract_instance = instance_double(RTesseract, to_s: ocr_text)
        allow(RTesseract).to receive(:new).with(frame_file, lang: described_class::OCR_LANGUAGES).and_return(rtesseract_instance)
      end

      it 'returns false' do
        expect(last_played_song).to be false
      end
    end

    context 'when an error occurs during processing' do
      let(:frame_result) { frame_file }

      before do
        allow(File).to receive(:exist?).with(frame_file).and_return(true)
        allow(RTesseract).to receive(:new).with(frame_file, lang: described_class::OCR_LANGUAGES).and_raise(StandardError, 'OCR failed')
        allow(Rails.logger).to receive(:warn).and_call_original
        allow(ExceptionNotifier).to receive(:notify).and_call_original
      end

      it 'returns false' do
        expect(last_played_song).to be false
      end

      it 'logs the error' do
        last_played_song
        expect(Rails.logger).to have_received(:warn).with(/YoursafeVideoProcessor: OCR failed/)
      end

      it 'notifies the exception tracker' do
        last_played_song
        expect(ExceptionNotifier).to have_received(:notify).with(instance_of(StandardError))
      end
    end
  end
end
