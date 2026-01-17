# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AcoustidPopulationJob do
  let(:job) { described_class.new }

  describe '#perform' do
    let(:song) { create(:song, title: 'Test Song', id_on_youtube: 'dQw4w9WgXcQ', acoustid_submitted_at: nil) }
    let(:artist) { create(:artist, name: 'Test Artist') }
    let(:downloader) { instance_double(YoutubeAudioDownloader) }
    let(:finder) { instance_double(MusicBrainz::RecordingFinder) }
    let(:submitter) { instance_double(AcoustidSubmitter) }

    before do
      song.artists << artist
      allow(YoutubeAudioDownloader).to receive(:new).and_return(downloader)
      allow(downloader).to receive(:download).and_return({ output_file: '/tmp/audio.mp3', duration: 212 })
      allow(downloader).to receive(:cleanup)

      allow(MusicBrainz::RecordingFinder).to receive(:new).and_return(finder)
      allow(finder).to receive(:find_recording_id).and_return('mb-recording-123')

      allow(AcoustidSubmitter).to receive(:new).and_return(submitter)
      allow(submitter).to receive(:submit).and_return(true)
    end

    context 'when song does not exist' do
      it 'does not raise an error' do
        expect { job.perform(999_999) }.not_to raise_error
      end
    end

    context 'when song has no YouTube ID' do
      let(:song) { create(:song, title: 'No YouTube', id_on_youtube: nil) }

      it 'returns early without processing' do
        job.perform(song.id)
        expect(YoutubeAudioDownloader).not_to have_received(:new)
      end
    end

    context 'when song was already submitted' do
      let(:song) { create(:song, id_on_youtube: 'dQw4w9WgXcQ', acoustid_submitted_at: 1.day.ago) }

      it 'returns early without processing' do
        job.perform(song.id)
        expect(YoutubeAudioDownloader).not_to have_received(:new)
      end
    end

    context 'when processing succeeds' do
      it 'downloads audio from YouTube', :aggregate_failures do
        job.perform(song.id)
        expect(YoutubeAudioDownloader).to have_received(:new).with('dQw4w9WgXcQ')
        expect(downloader).to have_received(:download)
      end

      it 'looks up MusicBrainz recording ID', :aggregate_failures do
        job.perform(song.id)
        expect(MusicBrainz::RecordingFinder).to have_received(:new).with(song)
        expect(finder).to have_received(:find_recording_id)
      end

      it 'submits fingerprint to AcoustID', :aggregate_failures do
        job.perform(song.id)
        expect(AcoustidSubmitter).to have_received(:new).with(
          audio_file_path: '/tmp/audio.mp3',
          musicbrainz_id: 'mb-recording-123',
          song: song
        )
        expect(submitter).to have_received(:submit)
      end

      it 'marks song as submitted' do
        job.perform(song.id)
        song.reload
        expect(song.acoustid_submitted_at).to be_present
      end

      it 'cleans up the downloaded file' do
        job.perform(song.id)
        expect(downloader).to have_received(:cleanup)
      end
    end

    context 'when MusicBrainz lookup fails' do
      before do
        allow(finder).to receive(:find_recording_id).and_raise(StandardError.new('API error'))
      end

      it 'continues without MusicBrainz ID' do
        job.perform(song.id)
        expect(AcoustidSubmitter).to have_received(:new).with(
          audio_file_path: '/tmp/audio.mp3',
          musicbrainz_id: nil,
          song: song
        )
      end
    end

    context 'when YouTube download fails' do
      before do
        allow(downloader).to receive(:download).and_raise(YoutubeAudioDownloader::DownloadError.new('Video unavailable'))
      end

      it 'raises the error for Sidekiq retry' do
        expect { job.perform(song.id) }.to raise_error(YoutubeAudioDownloader::DownloadError)
      end

      it 'still cleans up' do
        begin
          job.perform(song.id)
        rescue YoutubeAudioDownloader::DownloadError
          # Expected
        end
        expect(downloader).to have_received(:cleanup)
      end
    end

    context 'when AcoustID submission fails' do
      before do
        allow(submitter).to receive(:submit).and_raise(AcoustidSubmitter::SubmissionError.new('API error'))
      end

      it 'raises the error for Sidekiq retry' do
        expect { job.perform(song.id) }.to raise_error(AcoustidSubmitter::SubmissionError)
      end

      it 'does not mark song as submitted' do
        begin
          job.perform(song.id)
        rescue AcoustidSubmitter::SubmissionError
          # Expected
        end
        song.reload
        expect(song.acoustid_submitted_at).to be_nil
      end

      it 'still cleans up' do
        begin
          job.perform(song.id)
        rescue AcoustidSubmitter::SubmissionError
          # Expected
        end
        expect(downloader).to have_received(:cleanup)
      end
    end
  end

  describe '.enqueue_all' do
    let!(:song_with_youtube) { create(:song, id_on_youtube: 'abc123defgh', acoustid_submitted_at: nil) }
    let!(:song_already_submitted) { create(:song, id_on_youtube: 'xyz789uvwst', acoustid_submitted_at: 1.day.ago) }
    let!(:song_no_youtube) { create(:song, id_on_youtube: nil, acoustid_submitted_at: nil) }

    before do
      allow(described_class).to receive(:perform_async)
    end

    it 'enqueues jobs for songs with YouTube IDs that have not been submitted', :aggregate_failures do
      described_class.enqueue_all

      expect(described_class).to have_received(:perform_async).with(song_with_youtube.id)
      expect(described_class).not_to have_received(:perform_async).with(song_already_submitted.id)
      expect(described_class).not_to have_received(:perform_async).with(song_no_youtube.id)
    end

    it 'returns the count of enqueued jobs' do
      count = described_class.enqueue_all
      expect(count).to eq(1)
    end

    context 'with limit parameter' do
      before do
        create(:song, id_on_youtube: 'def456ghijk', acoustid_submitted_at: nil)
      end

      it 'respects the limit' do
        count = described_class.enqueue_all(limit: 1)
        expect(count).to eq(1)
      end
    end
  end
end
