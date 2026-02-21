# frozen_string_literal: true

# == Schema Information
#
# Table name: songs
#
#  id                     :bigint           not null, primary key
#  acoustid_submitted_at  :datetime
#  deezer_artwork_url     :string
#  deezer_preview_url     :string
#  deezer_song_url        :string
#  id_on_deezer           :string
#  id_on_itunes           :string
#  id_on_spotify          :string
#  id_on_youtube          :string
#  isrc                   :string
#  isrcs                  :string           default([]), is an Array
#  itunes_artwork_url     :string
#  itunes_preview_url     :string
#  itunes_song_url        :string
#  release_date           :date
#  release_date_precision :string
#  search_text            :text
#  spotify_artwork_url    :string
#  spotify_preview_url    :string
#  spotify_song_url       :string
#  title                  :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_songs_on_acoustid_submitted_at  (acoustid_submitted_at)
#  index_songs_on_id_on_deezer           (id_on_deezer)
#  index_songs_on_id_on_itunes           (id_on_itunes)
#  index_songs_on_release_date           (release_date)
#  index_songs_on_search_text            (search_text)
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
             :artists,
             :id_on_deezer,
             :deezer_song_url,
             :deezer_artwork_url,
             :deezer_preview_url,
             :id_on_itunes,
             :itunes_song_url,
             :itunes_artwork_url,
             :itunes_preview_url

  attribute :counter do |object|
    object.counter if object.respond_to?(:counter)
  end

  attribute :position do |object|
    object.position if object.respond_to?(:position)
  end

  attribute :daily_plays do |object|
    object.daily_plays if object.respond_to?(:daily_plays)
  end

  attribute :artists do |object|
    object.artists.map do |artist|
      options = { fields: { artist: %i[id name] } }
      ArtistSerializer.new(artist, options)
    end
  end

  attribute :music_profile do |object|
    if object.music_profile.present?
      {
        danceability: object.music_profile.danceability,
        energy: object.music_profile.energy,
        speechiness: object.music_profile.speechiness,
        acousticness: object.music_profile.acousticness,
        instrumentalness: object.music_profile.instrumentalness,
        liveness: object.music_profile.liveness,
        valence: object.music_profile.valence,
        tempo: object.music_profile.tempo
      }
    end
  end
end
