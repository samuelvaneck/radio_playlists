# frozen_string_literal: true

describe SongImportLogCleanupJob do
  let(:job) { described_class.new }

  describe '#perform' do
    let!(:old_log) { create(:song_import_log, :with_recognition, :old) }
    let!(:recent_log) { create(:song_import_log, :with_scraping) }

    after do
      FileUtils.rm_rf(described_class::CSV_EXPORT_DIR)
    end

    it 'deletes logs older than 1 day' do
      expect { job.perform }.to change(SongImportLog, :count).by(-1)
      expect(SongImportLog.exists?(old_log.id)).to be false
    end

    it 'keeps recent logs' do
      job.perform
      expect(SongImportLog.exists?(recent_log.id)).to be true
    end

    it 'exports old logs to CSV before deletion' do
      job.perform
      csv_files = Dir.glob(described_class::CSV_EXPORT_DIR.join('*.csv'))
      expect(csv_files).not_to be_empty
    end

    it 'creates CSV with correct data' do
      job.perform
      csv_file = Dir.glob(described_class::CSV_EXPORT_DIR.join('*.csv')).first
      csv_content = File.read(csv_file)

      expect(csv_content).to include(old_log.id.to_s)
      expect(csv_content).to include(old_log.recognized_artist)
    end

    context 'when there are no old logs' do
      before { old_log.destroy }

      it 'does not create a CSV file' do
        job.perform
        csv_files = Dir.glob(described_class::CSV_EXPORT_DIR.join('*.csv'))
        expect(csv_files).to be_empty
      end

      it 'does not delete any logs' do
        expect { job.perform }.not_to change(SongImportLog, :count)
      end
    end
  end

  describe 'CSV export directory' do
    it 'is in the tmp folder' do
      expect(described_class::CSV_EXPORT_DIR.to_s).to include('tmp/song_import_logs')
    end
  end
end
