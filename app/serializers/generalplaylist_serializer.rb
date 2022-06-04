# frozen_string_literal: true

# serializer for generaplaylist
class GeneralplaylistSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :broadcast_timestamp,
             :created_at,
             :song,
             :radiostation,
             :artists

  def song
    SongSerializer.new(object.song)
  end

  def radiostation
    RadiostationSerializer.new(object.radiostation)
  end

  def artists
    object.song.artists.each do |artist|
      ArtistSerializer.new(artist)
    end
  end
end
