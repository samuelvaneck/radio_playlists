# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AcoustidRecognizer, type: :service do
  let(:audio_file_path) { '/tmp/test_audio.mp3' }
  let(:api_key) { 'test_api_key' }
  let(:recognizer) { described_class.new(audio_file_path) }

  let(:fingerprint_output) do
    { 'fingerprint' => 'AQAA...fingerprint...', 'duration' => 5.0 }.to_json
  end

  let(:successful_api_response) do
    {
      'status' => 'ok',
      'results' => [
        {
          'id' => 'acoustid-123',
          'score' => 0.95,
          'recordings' => [
            {
              'id' => 'mb-recording-456',
              'title' => 'Test Song',
              'artists' => [
                { 'id' => 'mb-artist-789', 'name' => 'Test Artist' }
              ]
            }
          ]
        }
      ]
    }
  end

  before do
    allow(ENV).to receive(:fetch).with('ACOUSTID_API_KEY', nil).and_return(api_key)
    allow(File).to receive(:exist?).with(audio_file_path).and_return(true)
  end

  describe '#recognized?' do
    context 'when API key is missing' do
      let(:api_key) { nil }

      it 'returns false' do
        expect(recognizer.recognized?).to be false
      end
    end

    context 'when audio file does not exist' do
      before do
        allow(File).to receive(:exist?).with(audio_file_path).and_return(false)
      end

      it 'returns false' do
        expect(recognizer.recognized?).to be false
      end
    end

    context 'when fpcalc fails' do
      before do
        allow(Open3).to receive(:capture3)
                          .and_return(['', 'fpcalc error', instance_double(Process::Status, success?: false)])
      end

      it 'returns false' do
        expect(recognizer.recognized?).to be false
      end

      it 'logs a warning' do
        allow(Rails.logger).to receive(:warn)
        recognizer.recognized?
        expect(Rails.logger).to have_received(:warn).with(/fingerprint failed/)
      end
    end

    context 'when fpcalc succeeds but API returns no results' do
      let(:empty_api_response) do
        { 'status' => 'ok', 'results' => [] }
      end

      before do
        allow(Open3).to receive(:capture3)
                          .and_return([fingerprint_output, '', instance_double(Process::Status, success?: true)])
        stub_request(:get, /api.acoustid.org/)
          .to_return(status: 200, body: empty_api_response.to_json)
      end

      it 'returns false' do
        expect(recognizer.recognized?).to be false
      end
    end

    context 'when score is below minimum threshold' do
      let(:low_score_response) do
        {
          'status' => 'ok',
          'results' => [{ 'id' => 'acoustid-123', 'score' => 0.3, 'recordings' => [] }]
        }
      end

      before do
        allow(Open3).to receive(:capture3)
                          .and_return([fingerprint_output, '', instance_double(Process::Status, success?: true)])
        stub_request(:get, /api.acoustid.org/)
          .to_return(status: 200, body: low_score_response.to_json)
      end

      it 'returns false' do
        expect(recognizer.recognized?).to be false
      end
    end

    context 'when recognition is successful' do
      before do
        allow(Open3).to receive(:capture3)
                          .and_return([fingerprint_output, '', instance_double(Process::Status, success?: true)])
        stub_request(:get, /api.acoustid.org/)
          .to_return(status: 200, body: successful_api_response.to_json)
      end

      it 'returns true' do
        expect(recognizer.recognized?).to be true
      end

      it 'sets the title', :aggregate_failures do
        recognizer.recognized?
        expect(recognizer.title).to eq('Test Song')
      end

      it 'sets the artist_name' do
        recognizer.recognized?
        expect(recognizer.artist_name).to eq('Test Artist')
      end

      it 'sets the recording_id' do
        recognizer.recognized?
        expect(recognizer.recording_id).to eq('mb-recording-456')
      end

      it 'sets the score' do
        recognizer.recognized?
        expect(recognizer.score).to eq(0.95)
      end

      it 'sets the result', :aggregate_failures do
        recognizer.recognized?
        expect(recognizer.result).to be_a(Hash)
        expect(recognizer.result[:status]).to eq('ok')
      end
    end

    context 'when recording has multiple artists' do
      let(:multi_artist_response) do
        {
          'status' => 'ok',
          'results' => [
            {
              'id' => 'acoustid-123',
              'score' => 0.95,
              'recordings' => [
                {
                  'id' => 'mb-recording-456',
                  'title' => 'Collaboration Song',
                  'artists' => [
                    { 'id' => 'artist-1', 'name' => 'Artist One' },
                    { 'id' => 'artist-2', 'name' => 'Artist Two' }
                  ]
                }
              ]
            }
          ]
        }
      end

      before do
        allow(Open3).to receive(:capture3)
                          .and_return([fingerprint_output, '', instance_double(Process::Status, success?: true)])
        stub_request(:get, /api.acoustid.org/)
          .to_return(status: 200, body: multi_artist_response.to_json)
      end

      it 'joins multiple artist names with comma' do
        recognizer.recognized?
        expect(recognizer.artist_name).to eq('Artist One, Artist Two')
      end
    end

    context 'when API returns an error status' do
      let(:error_response) do
        { 'status' => 'error', 'error' => { 'message' => 'Invalid API key' } }
      end

      before do
        allow(Open3).to receive(:capture3)
                          .and_return([fingerprint_output, '', instance_double(Process::Status, success?: true)])
        stub_request(:get, /api.acoustid.org/)
          .to_return(status: 200, body: error_response.to_json)
      end

      it 'returns false' do
        expect(recognizer.recognized?).to be false
      end

      it 'logs a warning' do
        allow(Rails.logger).to receive(:warn)
        recognizer.recognized?
        expect(Rails.logger).to have_received(:warn).with(/returned status: error/)
      end
    end

    context 'when API returns HTTP error' do
      before do
        allow(Open3).to receive(:capture3)
                          .and_return([fingerprint_output, '', instance_double(Process::Status, success?: true)])
        stub_request(:get, /api.acoustid.org/)
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'returns false' do
        expect(recognizer.recognized?).to be false
      end

      it 'logs an error' do
        allow(Rails.logger).to receive(:error)
        recognizer.recognized?
        expect(Rails.logger).to have_received(:error).with(/API error/)
      end
    end
  end
end
