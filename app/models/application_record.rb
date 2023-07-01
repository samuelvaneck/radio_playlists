class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  scope :played_between, lambda { |start_time, end_time|
    where('playlists.created_at > ? AND playlists.created_at < ? ', start_time, end_time)
  }
  scope :played_on, lambda { |radio_station_id|
    where('playlists.radio_station_id = ?', radio_station_id) if radio_station_id.present?
  }
end
