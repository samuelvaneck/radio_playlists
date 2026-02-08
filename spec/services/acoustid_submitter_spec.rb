# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AcoustidSubmitter, type: :service do
  let(:audio_file_path) { '/tmp/test_audio.mp3' }
  let(:musicbrainz_id) { 'mb-recording-123' }
  let(:artist) { create(:artist, name: 'Test Artist') }
  let(:song) { create(:song, title: 'Test Song', artists: [artist]) }
  let(:api_key) { 'test_api_key' }
  let(:user_key) { 'test_user_key' }
  let(:submitter) { described_class.new(audio_file_path: audio_file_path, musicbrainz_id: musicbrainz_id, song: song) }

  let(:fingerprint_output) do
    { 'fingerprint' => 'AQAA...fingerprint...', 'duration' => 212 }.to_json
  end

  let(:successful_response) do
    {
      'status' => 'ok',
      'submissions' => [{ 'id' => 12_345, 'status' => 'pending' }]
    }
  end

  before do
    allow(ENV).to receive(:fetch).with('ACOUSTID_API_KEY', nil).and_return(api_key)
    allow(ENV).to receive(:fetch).with('ACOUSTID_USER_KEY', nil).and_return(user_key)
    allow(File).to receive(:exist?).with(audio_file_path).and_return(true)
  end

  describe '#submit' do
    context 'when API key is missing' do
      let(:api_key) { nil }

      it 'raises a SubmissionError' do
        expect { submitter.submit }.to raise_error(described_class::SubmissionError, /ACOUSTID_API_KEY is not configured/)
      end
    end

    context 'when user key is missing' do
      let(:user_key) { nil }

      it 'raises a SubmissionError' do
        expect { submitter.submit }.to raise_error(described_class::SubmissionError, /ACOUSTID_USER_KEY is not configured/)
      end
    end

    context 'when audio file path is blank' do
      let(:submitter) { described_class.new(audio_file_path: nil, musicbrainz_id: musicbrainz_id) }

      it 'raises a FingerprintError' do
        expect { submitter.submit }.to raise_error(described_class::FingerprintError, /Audio file path is required/)
      end
    end

    context 'when audio file does not exist' do
      before do
        allow(File).to receive(:exist?).with(audio_file_path).and_return(false)
      end

      it 'raises a FingerprintError' do
        expect { submitter.submit }.to raise_error(described_class::FingerprintError, /Audio file not found/)
      end
    end

    context 'when fpcalc fails' do
      before do
        allow(Open3).to receive(:capture3)
                          .and_return(['', 'fpcalc error', instance_double(Process::Status, success?: false)])
      end

      it 'raises a FingerprintError' do
        expect { submitter.submit }.to raise_error(described_class::FingerprintError, /fpcalc failed/)
      end
    end

    context 'when submission is successful' do
      before do
        allow(Open3).to receive(:capture3)
                          .and_return([fingerprint_output, '', instance_double(Process::Status, success?: true)])
        stub_request(:post, 'https://api.acoustid.org/v2/submit')
          .to_return(status: 200, body: successful_response.to_json)
      end

      it 'returns true' do
        expect(submitter.submit).to be true
      end

      it 'sets the submission_id' do
        submitter.submit
        expect(submitter.submission_id).to eq(12_345)
      end

      it 'sets submitted? to true' do
        submitter.submit
        expect(submitter.submitted?).to be true
      end

      it 'sends correct parameters' do
        submitter.submit
        expected_params = { 'client' => api_key, 'user' => user_key, 'duration.0' => '212', 'mbid.0' => musicbrainz_id,
                            'track.0' => 'Test Song', 'artist.0' => 'Test Artist' }
        expect(WebMock).to have_requested(:post, 'https://api.acoustid.org/v2/submit')
                             .with(body: hash_including(expected_params))
      end
    end

    context 'when submission succeeds without musicbrainz_id' do
      let(:submitter) { described_class.new(audio_file_path: audio_file_path, musicbrainz_id: nil, song: song) }

      before do
        allow(Open3).to receive(:capture3)
                          .and_return([fingerprint_output, '', instance_double(Process::Status, success?: true)])
        stub_request(:post, 'https://api.acoustid.org/v2/submit')
          .to_return(status: 200, body: successful_response.to_json)
      end

      it 'does not include mbid parameter' do
        submitter.submit
        expect(WebMock).to(have_requested(:post, 'https://api.acoustid.org/v2/submit')
          .with { |req| !req.body.include?('mbid.0') })
      end
    end

    context 'when API returns error status' do
      let(:error_response) do
        { 'status' => 'error', 'error' => { 'message' => 'Invalid fingerprint' } }
      end

      before do
        allow(Open3).to receive(:capture3)
                          .and_return([fingerprint_output, '', instance_double(Process::Status, success?: true)])
        stub_request(:post, 'https://api.acoustid.org/v2/submit')
          .to_return(status: 200, body: error_response.to_json)
      end

      it 'raises an ApiError' do
        expect { submitter.submit }.to raise_error(described_class::ApiError, /Invalid fingerprint/)
      end
    end

    context 'when API returns HTTP error' do
      before do
        allow(Open3).to receive(:capture3)
                          .and_return([fingerprint_output, '', instance_double(Process::Status, success?: true)])
        stub_request(:post, 'https://api.acoustid.org/v2/submit')
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises an ApiError' do
        expect { submitter.submit }.to raise_error(described_class::ApiError)
      end
    end
  end
end
