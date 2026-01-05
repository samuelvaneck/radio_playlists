# frozen_string_literal: true

# == Schema Information
#
# Table name: air_plays
#
#  id               :bigint           not null, primary key
#  broadcasted_at   :datetime
#  scraper_import   :boolean          default(FALSE)
#  status           :integer          default("confirmed"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  radio_station_id :bigint
#  song_id          :bigint
#
# Indexes
#
#  air_play_radio_song_time             (song_id,radio_station_id,broadcasted_at) UNIQUE
#  index_air_plays_on_broadcasted_at    (broadcasted_at)
#  index_air_plays_on_radio_station_id  (radio_station_id)
#  index_air_plays_on_song_id           (song_id)
#  index_air_plays_on_status            (status)
#
# Foreign Keys
#
#  fk_rails_...  (radio_station_id => radio_stations.id)
#  fk_rails_...  (song_id => songs.id)
#
class AirPlaySerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :broadcasted_at,
             :created_at,
             :status,
             :song,
             :radio_station,
             :artists

  def radio_station
    RadioStationSerializer.new(object.radio_station)
  end

  attributes :song do |object|
    options = { fields: { song: %i[id title spotify_artwork_url spotify_song_url spotify_preview_url id_on_youtube
                                   deezer_artwork_url deezer_preview_url deezer_song_url itunes_artwork_url
                                   itunes_preview_url itunes_song_url] } }
    SongSerializer.new(object.song, options)
  end

  attributes :artists do |object|
    object.song.artists.map do |artist|
      options = { fields: { artist: %i[id name] } }
      ArtistSerializer.new(artist, options)
    end
  end
end
