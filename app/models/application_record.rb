class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  scope :played_between, lambda { |start_time, end_time|
    where('playlists.created_at > ? AND playlists.created_at < ? ', start_time, end_time)
  }
  scope :played_on, lambda { |radio_station|
    where('playlists.radio_station_id = ?', radio_station.id) if radio_station
  }

  def self.parsed_time(time:, fallback:)
    time.present? ? Time.zone.strptime(time, '%Y-%m-%dT%R') : fallback
  end

  def self.parsed_radio_station(id)
    RadioStation.find(id) if id.present?
  end
end
