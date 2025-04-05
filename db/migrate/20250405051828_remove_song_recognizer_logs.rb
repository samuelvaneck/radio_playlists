class RemoveSongRecognizerLogs < ActiveRecord::Migration[8.0]
  def up
    drop_table :song_recognizer_logs, if_exists: true
  end

  def down
    create_table :song_recognizer_logs do |t|
      t.references :radio_station, null: false, foreign_key: true
      t.integer :song_match
      t.string :recognizer_song_fullname
      t.string :api_song_fullname

      t.timestamps
    end
  end
end
