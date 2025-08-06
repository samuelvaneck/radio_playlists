# frozen_string_literal: true

# == Schema Information
#
# Table name: songs
#
#  id                                :bigint           not null, primary key
#  cached_chart_positions            :jsonb
#  cached_chart_positions_updated_at :datetime
#  id_on_spotify                     :string
#  id_on_youtube                     :string
#  isrc                              :string
#  release_date                      :date
#  search_text                       :text
#  spotify_artwork_url               :string
#  spotify_preview_url               :string
#  spotify_song_url                  :string
#  title                             :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#
# Indexes
#
#  index_songs_on_release_date  (release_date)
#  index_songs_on_search_text   (search_text)
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
             :release_date,
             :release_date_precision,
             :artists

  attribute :counter do |object|
    object.counter if object.respond_to?(:counter)
  end

  attribute :position do |object|
    object.position if object.respond_to?(:position)
  end

  attribute :artists do |object|
    object.artists.map do |artist|
      options = { fields: { artist: %i[id name] } }
      ArtistSerializer.new(artist, options)
    end
  end
end
