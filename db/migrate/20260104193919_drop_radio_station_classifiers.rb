class DropRadioStationClassifiers < ActiveRecord::Migration[8.1]
  def up
    drop_table :radio_station_classifiers
  end

  def down
    create_table :radio_station_classifiers do |t|
      t.references :radio_station, null: false, foreign_key: true
      t.string :day_part, null: false
      t.integer :counter, default: 0
      t.integer :danceability, default: 0
      t.decimal :danceability_average, precision: 5, scale: 3, default: 0.0
      t.integer :energy, default: 0
      t.decimal :energy_average, precision: 5, scale: 3, default: 0.0
      t.integer :speechiness, default: 0
      t.decimal :speechiness_average, precision: 5, scale: 3, default: 0.0
      t.integer :acousticness, default: 0
      t.decimal :acousticness_average, precision: 5, scale: 3, default: 0.0
      t.integer :instrumentalness, default: 0
      t.decimal :instrumentalness_average, precision: 5, scale: 3, default: 0.0
      t.integer :liveness, default: 0
      t.decimal :liveness_average, precision: 5, scale: 3, default: 0.0
      t.integer :valence, default: 0
      t.decimal :valence_average, precision: 5, scale: 3, default: 0.0
      t.decimal :tempo, precision: 5, scale: 2, default: 0.0
      t.timestamps
    end

    add_index :radio_station_classifiers, %i[radio_station_id day_part], unique: true
  end
end
