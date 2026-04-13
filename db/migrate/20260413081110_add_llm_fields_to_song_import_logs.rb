class AddLlmFieldsToSongImportLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :song_import_logs, :llm_action, :string
    add_column :song_import_logs, :llm_raw_response, :jsonb, default: {}
  end
end
