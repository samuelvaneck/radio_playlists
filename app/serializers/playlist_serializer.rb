# frozen_string_literal: true

# == Schema Information
#
# Table name: playlists
#
#  id               :bigint           not null, primary key
#  broadcasted_at   :datetime
#  scraper_import   :boolean          default(FALSE)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  radio_station_id :bigint
#  song_id          :bigint
#
# Indexes
#
#  index_playlists_on_radio_station_id  (radio_station_id)
#  index_playlists_on_song_id           (song_id)
#  playlist_radio_song_time             (song_id,radio_station_id,broadcasted_at) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (radio_station_id => radio_stations.id)
#  fk_rails_...  (song_id => songs.id)
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
