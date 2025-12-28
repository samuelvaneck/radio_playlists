class ChangeRadioStationClassifierCountersToPercentages < ActiveRecord::Migration[8.1]
  def up
    # Rename columns to reflect their new meaning (percentage of tracks exceeding 0.5 threshold)
    rename_column :radio_station_classifiers, :danceability, :high_danceability_percentage
    rename_column :radio_station_classifiers, :energy, :high_energy_percentage
    rename_column :radio_station_classifiers, :speechiness, :high_speechiness_percentage
    rename_column :radio_station_classifiers, :acousticness, :high_acousticness_percentage
    rename_column :radio_station_classifiers, :instrumentalness, :high_instrumentalness_percentage
    rename_column :radio_station_classifiers, :liveness, :high_liveness_percentage
    rename_column :radio_station_classifiers, :valence, :high_valence_percentage

    # Change column types from integer to decimal for percentages (0.0 - 1.0)
    change_column :radio_station_classifiers, :high_danceability_percentage, :decimal, precision: 5, scale: 4, default: 0.0
    change_column :radio_station_classifiers, :high_energy_percentage, :decimal, precision: 5, scale: 4, default: 0.0
    change_column :radio_station_classifiers, :high_speechiness_percentage, :decimal, precision: 5, scale: 4, default: 0.0
    change_column :radio_station_classifiers, :high_acousticness_percentage, :decimal, precision: 5, scale: 4, default: 0.0
    change_column :radio_station_classifiers, :high_instrumentalness_percentage, :decimal, precision: 5, scale: 4, default: 0.0
    change_column :radio_station_classifiers, :high_liveness_percentage, :decimal, precision: 5, scale: 4, default: 0.0
    change_column :radio_station_classifiers, :high_valence_percentage, :decimal, precision: 5, scale: 4, default: 0.0

    # Convert existing count data to percentages
    # percentage = count / total_counter (capped at 1.0)
    execute <<-SQL
      UPDATE radio_station_classifiers
      SET
        high_danceability_percentage = CASE WHEN counter > 0 THEN LEAST(high_danceability_percentage / counter, 1.0) ELSE 0.0 END,
        high_energy_percentage = CASE WHEN counter > 0 THEN LEAST(high_energy_percentage / counter, 1.0) ELSE 0.0 END,
        high_speechiness_percentage = CASE WHEN counter > 0 THEN LEAST(high_speechiness_percentage / counter, 1.0) ELSE 0.0 END,
        high_acousticness_percentage = CASE WHEN counter > 0 THEN LEAST(high_acousticness_percentage / counter, 1.0) ELSE 0.0 END,
        high_instrumentalness_percentage = CASE WHEN counter > 0 THEN LEAST(high_instrumentalness_percentage / counter, 1.0) ELSE 0.0 END,
        high_liveness_percentage = CASE WHEN counter > 0 THEN LEAST(high_liveness_percentage / counter, 1.0) ELSE 0.0 END,
        high_valence_percentage = CASE WHEN counter > 0 THEN LEAST(high_valence_percentage / counter, 1.0) ELSE 0.0 END
    SQL
  end

  def down
    # Convert percentages back to counts (approximate)
    execute <<-SQL
      UPDATE radio_station_classifiers
      SET
        high_danceability_percentage = ROUND(high_danceability_percentage * counter),
        high_energy_percentage = ROUND(high_energy_percentage * counter),
        high_speechiness_percentage = ROUND(high_speechiness_percentage * counter),
        high_acousticness_percentage = ROUND(high_acousticness_percentage * counter),
        high_instrumentalness_percentage = ROUND(high_instrumentalness_percentage * counter),
        high_liveness_percentage = ROUND(high_liveness_percentage * counter),
        high_valence_percentage = ROUND(high_valence_percentage * counter)
    SQL

    # Change column types back to integer
    change_column :radio_station_classifiers, :high_danceability_percentage, :integer, default: 0
    change_column :radio_station_classifiers, :high_energy_percentage, :integer, default: 0
    change_column :radio_station_classifiers, :high_speechiness_percentage, :integer, default: 0
    change_column :radio_station_classifiers, :high_acousticness_percentage, :integer, default: 0
    change_column :radio_station_classifiers, :high_instrumentalness_percentage, :integer, default: 0
    change_column :radio_station_classifiers, :high_liveness_percentage, :integer, default: 0
    change_column :radio_station_classifiers, :high_valence_percentage, :integer, default: 0

    # Rename columns back
    rename_column :radio_station_classifiers, :high_danceability_percentage, :danceability
    rename_column :radio_station_classifiers, :high_energy_percentage, :energy
    rename_column :radio_station_classifiers, :high_speechiness_percentage, :speechiness
    rename_column :radio_station_classifiers, :high_acousticness_percentage, :acousticness
    rename_column :radio_station_classifiers, :high_instrumentalness_percentage, :instrumentalness
    rename_column :radio_station_classifiers, :high_liveness_percentage, :liveness
    rename_column :radio_station_classifiers, :high_valence_percentage, :valence
  end
end
