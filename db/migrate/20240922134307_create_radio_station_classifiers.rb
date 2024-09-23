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
      t.string :day_part, null: false
      t.decimal :tempo, precision: 5, scale: 2, default: 0.0
      t.integer :counter, default: 0
      t.index %i[radio_station_id day_part], unique: true

      t.timestamps
    end
  end
end
