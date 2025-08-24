class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  scope :played_between, lambda { |start_time, end_time|
    where(air_plays: { created_at: start_time..end_time })
  }
  scope :played_on, lambda { |radio_station_ids|
    return if radio_station_ids.blank?

    radio_station_ids = JSON.parse(radio_station_ids) if radio_station_ids.is_a?(String)
    where(air_plays: { radio_station_id: radio_station_ids })
  }
end
