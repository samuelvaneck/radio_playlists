# frozen_string_literal: true

# == Schema Information
#
# Table name: songs
#
#  id                                :bigint           not null, primary key
#  title                             :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  fullname                          :text
#  spotify_song_url                  :string
#  spotify_artwork_url               :string
#  id_on_spotify                     :string
#  isrc                              :string
#  spotify_preview_url               :string
#  cached_chart_positions            :jsonb
#  cached_chart_positions_updated_at :datetime
#  id_on_youtube                     :string
#
class SongSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :title,
             :fullname,
             :spotify_song_url,
             :spotify_artwork_url,
             :spotify_preview_url,
             :artists

  attribute :counter do |object|
    object.counter if object.respond_to?(:counter)
  end

  def artists
    object.artists.map do |artist|
      ArtistSerializer.new(artist)
    end
  end
end
