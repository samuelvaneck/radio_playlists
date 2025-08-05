# == Schema Information
#
# Table name: radio_station_songs
#
#  id                   :bigint           not null, primary key
#  first_broadcasted_at :datetime
#  radio_station_id     :bigint           not null
#  song_id              :bigint           not null
#
# Indexes
#
#  index_radio_station_songs_on_first_broadcasted_at          (first_broadcasted_at)
#  index_radio_station_songs_on_radio_station_id              (radio_station_id)
#  index_radio_station_songs_on_song_id                       (song_id)
#  index_radio_station_songs_on_song_id_and_radio_station_id  (song_id,radio_station_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (radio_station_id => radio_stations.id)
#  fk_rails_...  (song_id => songs.id)
#
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
