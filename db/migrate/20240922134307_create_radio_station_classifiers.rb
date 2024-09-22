class CreateRadioStationClassifiers < ActiveRecord::Migration[7.2]
  def change
    create_table :radio_station_classifiers do |t|
      t.references :radio_station, null: false, foreign_key: true
      t.integer :danceable
      t.integer :energy
      t.integer :speech
      t.integer :acoustic
      t.integer :instrumental
      t.integer :live
      t.integer :valance
      t.string :day_part
      t.jsonb :tags

      t.timestamps
    end
  end
end
