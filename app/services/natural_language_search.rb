# frozen_string_literal: true

class NaturalLanguageSearch
  attr_reader :query, :filters

  def initialize(query)
    @query = query
    @filters = {}
  end

  def search
    @filters = Llm::QueryTranslator.new(query).translate
    return empty_result if filters.blank?

    if artist_search?
      search_artists
    else
      search_songs
    end
  end

  private

  def artist_search?
    filters[:search_type] == 'artists'
  end

  def search_songs
    params = build_song_params
    songs = Song.most_played(params)
    songs = apply_song_facets(songs)
    songs = apply_sorting(songs)
    apply_limit(songs)
  end

  def search_artists
    params = build_artist_params
    artists = Artist.most_played(params)
    artists = apply_artist_facets(artists)
    apply_limit(artists)
  end

  def build_song_params
    params = {}
    params[:period] = filters[:period].presence || 'all'
    params[:radio_station_ids] = resolve_radio_station_ids if filters[:radio_station].present?
    params[:search_term] = filters[:text_search] if filters[:text_search].present?
    params[:music_profile] = build_music_profile_params
    params
  end

  def build_artist_params
    params = {}
    params[:period] = filters[:period].presence || 'all'
    params[:radio_station_ids] = resolve_radio_station_ids if filters[:radio_station].present?
    params[:search_term] = filters[:text_search] || filters[:artist]
    params
  end

  def apply_song_facets(scope)
    scope = apply_song_text_facets(scope)
    scope = apply_genre_filter(scope) if filters[:genre].present?
    scope = apply_country_filter(scope) if filters[:country].present?
    scope
  end

  def apply_song_text_facets(scope)
    scope = scope.filter_by_artist(filters[:artist]) if filters[:artist].present?
    scope = scope.filter_by_title(filters[:title]) if filters[:title].present?
    scope = scope.filter_by_album(filters[:album]) if filters[:album].present?
    scope = scope.filter_by_year_range(year_from: filters[:year_from], year_to: filters[:year_to]) if year_filter?
    scope
  end

  def year_filter?
    filters[:year_from].present? || filters[:year_to].present?
  end

  def apply_artist_facets(scope)
    scope = scope.filter_by_genre(filters[:genre]) if filters[:genre].present?
    scope = scope.filter_by_country(filters[:country]) if filters[:country].present?
    scope
  end

  def apply_genre_filter(scope)
    scope.joins(:artists).where('artists.genres @> ARRAY[?]::varchar[]', filters[:genre])
  end

  def apply_country_filter(scope)
    scope.joins(:artists).where('artists.country_of_origin @> ARRAY[?]::varchar[]', filters[:country])
  end

  def apply_sorting(scope)
    case filters[:sort_by]
    when 'newest'
      scope.reorder(Arel.sql('songs.release_date DESC NULLS LAST'))
    when 'popularity'
      scope.reorder(Arel.sql('COALESCE(songs.popularity, 0) DESC'))
    else
      scope
    end
  end

  def apply_limit(scope)
    return scope if filters[:limit].blank?

    scope.limit(filters[:limit])
  end

  def build_music_profile_params
    return nil if filters[:mood].blank?

    mood_filters = Llm::QueryTranslator::MOOD_MAPPINGS[filters[:mood]]
    return nil if mood_filters.blank?

    mood_filters.transform_keys(&:to_s)
  end

  def resolve_radio_station_ids
    name = filters[:radio_station].downcase
    sanitized = ActiveRecord::Base.sanitize_sql_like(name)

    station = RadioStation
                .where('LOWER(name) = ? OR LOWER(name) LIKE ?', name, "%#{sanitized}%")
                .order(Arel.sql("CASE WHEN LOWER(name) = #{ActiveRecord::Base.connection.quote(name)} THEN 0 ELSE 1 END"))
                .pick(:id)
    return nil if station.blank?

    [station]
  end

  def empty_result
    Song.none
  end
end
