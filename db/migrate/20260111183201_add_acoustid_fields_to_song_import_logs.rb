# frozen_string_literal: true

class AddAcoustidFieldsToSongImportLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :song_import_logs, :acoustid_artist, :string
    add_column :song_import_logs, :acoustid_title, :string
    add_column :song_import_logs, :acoustid_recording_id, :string
    add_column :song_import_logs, :acoustid_score, :decimal, precision: 5, scale: 4
    add_column :song_import_logs, :acoustid_raw_response, :jsonb
  end
end
