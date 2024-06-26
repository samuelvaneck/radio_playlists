# frozen_string_literal: true

# == Schema Information
#
# Table name: playlists
#
#  id               :bigint           not null, primary key
#  song_id          :bigint
#  radio_station_id :bigint
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  broadcasted_at   :datetime
#  scraper_import   :boolean          default(FALSE)
#
class PlaylistSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :broadcasted_at,
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
