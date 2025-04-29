# frozen_string_literal: true

# == Schema Information
#
# Table name: songs
#
#  id                                :bigint           not null, primary key
#  title                             :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  search_text                       :text
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
             :search_text,
             :spotify_song_url,
             :spotify_artwork_url,
             :spotify_preview_url,
             :id_on_youtube,
             :artists

  attribute :counter do |object|
    object.counter if object.respond_to?(:counter)
  end

  attribute :artists do |object|
    object.artists.map do |artist|
      options = { fields: { artist: %i[id name] } }
      ArtistSerializer.new(artist, options)
    end
  end
end
