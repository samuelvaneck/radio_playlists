# frozen_string_literal: true

# == Schema Information
#
# Table name: songs
#
#  id                     :bigint           not null, primary key
#  acoustid_submitted_at  :datetime
#  album_name             :string
#  deezer_artwork_url     :string
#  deezer_preview_url     :string
#  deezer_song_url        :string
#  duration_ms            :integer
#  explicit               :boolean          default(FALSE)
#  hit_potential_score    :decimal(5, 2)
#  id_on_deezer           :string
#  id_on_itunes           :string
#  id_on_spotify          :string
#  id_on_tidal            :string
#  id_on_youtube          :string
#  isrc                   :string
#  isrcs                  :string           default([]), is an Array
#  itunes_artwork_url     :string
#  itunes_preview_url     :string
#  itunes_song_url        :string
#  lastfm_enriched_at     :datetime
#  lastfm_listeners       :bigint
#  lastfm_playcount       :bigint
#  lastfm_tags            :string           default([]), is an Array
#  normalized_title       :string
#  popularity             :integer
#  release_date           :date
#  release_date_precision :string
#  search_text            :text
#  slug                   :string
#  spotify_artwork_url    :string
#  spotify_preview_url    :string
#  spotify_song_url       :string
#  tidal_artwork_url      :string
#  tidal_preview_url      :string
#  tidal_song_url         :string
#  title                  :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_songs_on_acoustid_submitted_at  (acoustid_submitted_at)
#  index_songs_on_id_on_deezer           (id_on_deezer)
#  index_songs_on_id_on_itunes           (id_on_itunes)
#  index_songs_on_id_on_tidal            (id_on_tidal)
#  index_songs_on_normalized_title       (normalized_title)
#  index_songs_on_release_date           (release_date)
#  index_songs_on_search_text_trgm       (search_text) USING gin
#  index_songs_on_slug                   (slug) UNIQUE
#
class SongSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :title,
             :slug,
             :search_text,
             :album_name,
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
             :itunes_preview_url,
             :id_on_tidal,
             :tidal_song_url,
             :tidal_artwork_url,
             :tidal_preview_url,
             :duration_ms,
             :popularity,
             :explicit,
             :lastfm_listeners,
             :lastfm_playcount,
             :lastfm_tags,
             :hit_potential_score

  attribute :counter do |object|
    object.counter if object.respond_to?(:counter)
  end

  attribute :position do |object|
    object.position if object.respond_to?(:position)
  end

  attribute :artists do |object|
    object.artists.map do |artist|
      options = { fields: { artist: %i[id name country_of_origin] } }
      ArtistSerializer.new(artist, options)
    end
  end

  attribute :in_chart do |object, params|
    params.dig(:chart_data, object.id, :in_chart)
  end

  attribute :last_chart_date do |object, params|
    params.dig(:chart_data, object.id, :last_chart_date)
  end

  attribute :hit_potential_breakdown do |object|
    HitPotentialCalculator.new(object).breakdown
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
        tempo: object.music_profile.tempo,
        key: object.music_profile.key,
        mode: object.music_profile.mode,
        loudness: object.music_profile.loudness,
        time_signature: object.music_profile.time_signature
      }
    end
  end
end
