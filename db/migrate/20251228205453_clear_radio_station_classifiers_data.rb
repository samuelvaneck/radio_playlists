class ClearRadioStationClassifiersData < ActiveRecord::Migration[8.1]
  def up
    # Clear all classifier data because the threshold logic has changed:
    # - speechiness threshold changed from 0.5 to 0.33
    # - liveness threshold changed from 0.5 to 0.8
    # The data will automatically rebuild as songs are played via RadioStationClassifierJob
    execute "DELETE FROM radio_station_classifiers"

    Rails.logger.info "Cleared #{RadioStationClassifier.count} radio station classifiers - data will rebuild automatically"
  end

  def down
    # Data cannot be restored - it will rebuild naturally as songs are played
    Rails.logger.warn "Radio station classifier data was cleared and cannot be restored. It will rebuild automatically."
  end
end
