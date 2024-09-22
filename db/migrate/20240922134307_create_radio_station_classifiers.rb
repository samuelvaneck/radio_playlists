class CreateRadioStationClassifiers < ActiveRecord::Migration[7.2]
  def change
    create_table :radio_station_classifiers do |t|
      t.references :radio_station, null: false, foreign_key: true
      t.integer :danceable, default: 0
      t.integer :energy, default: 0
      t.integer :speech, default: 0
      t.integer :acoustic, default: 0
      t.integer :instrumental, default: 0
      t.integer :live, default: 0
      t.integer :valence, default: 0
      t.string :day_part
      t.jsonb :tags, default: {}

      t.timestamps
    end
  end
end
