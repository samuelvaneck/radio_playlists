class CreateSongRecognizerLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :song_recognizer_logs do |t|
      t.references :radio_station, null: false, foreign_key: true
      t.integer :song_match
      t.string :recognizer_song_fullname
      t.string :api_song_fullname

      t.timestamps
    end
  end
end
