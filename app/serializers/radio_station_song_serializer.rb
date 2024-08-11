class RadioStationSongSerializer
  include FastJsonapi::ObjectSerializer

  attributes :song, :radio_station, :first_broadcasted_at, :counter

  attribute :counter do |object|
    object.song.playlists.where(radio_station_id: object.radio_station_id).count
  end

  attribute :song do |object|
    SongSerializer.new(object.song)
  end

  attribute :radio_station do |object|
    RadioStationSerializer.new(object.radio_station)
  end
end
