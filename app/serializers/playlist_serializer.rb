# frozen_string_literal: true

# serializer for generaplaylist
class PlaylistSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :broadcast_timestamp,
             :created_at,
             :song,
             :radio_station,
             :artists

  def song
    SongSerializer.new(object.song)
  end

  def radio_station
    RadioStationSerializer.new(object.radio_station)
  end

  def artists
    object.song.artists.each do |artist|
      ArtistSerializer.new(artist)
    end
  end
end
