# frozen_string_literal: true

module ArtistSearchConcern
  extend ActiveSupport::Concern

  SEARCH_FIELDS = %w[name genre country].freeze

  included do
    scope :filter_by_name, lambda { |name|
      return all if name.blank?

      name_col = arel_table[:name]
      trigram = Arel::Nodes::InfixOperation.new('%', name_col, Arel::Nodes.build_quoted(name))
      where(trigram.or(name_col.matches("%#{sanitize_sql_like(name)}%")))
    }
    scope :filter_by_genre, lambda { |genre|
      return all if genre.blank?

      where('genres @> ARRAY[?]::varchar[]', genre)
    }
    scope :filter_by_country, lambda { |country|
      return all if country.blank?

      where('country_of_origin @> ARRAY[?]::varchar[]', country)
    }
    scope :sorted_by_air_plays, lambda {
      joins(:air_plays)
        .merge(AirPlay.confirmed)
        .select('artists.*, COUNT(DISTINCT air_plays.id) AS air_plays_count')
        .group('artists.id')
        .order(Arel.sql('air_plays_count DESC'))
    }
  end

  class_methods do
    def faceted_search(filters = {})
      scope = all
      scope = scope.search_by_name(filters[:q]) if filters[:q].present?
      scope = scope.filter_by_name(filters[:name])
                .filter_by_genre(filters[:genre])
                .filter_by_country(filters[:country])
                .limit(filters.fetch(:limit, 10))
      apply_faceted_sort(scope, filters[:sort_by])
    end

    def suggest(field:, query: nil, limit: 5)
      case field
      when 'name' then suggest_names(query, limit)
      when 'genre' then suggest_genres(query, limit)
      when 'country' then suggest_countries(query, limit)
      else SEARCH_FIELDS
      end
    end

    private

    def apply_faceted_sort(scope, sort_by)
      case sort_by
      when 'most_played' then scope.sorted_by_air_plays
      else scope.order(spotify_popularity: :desc)
      end
    end

    def suggest_names(query, limit)
      if query.present?
        name_col = arel_table[:name]
        scope = where(trigram_or_ilike(name_col, query))
                  .order(*SongSearchConcern.relevance_order('artists.name', query), spotify_popularity: :desc)
      else
        scope = order(spotify_popularity: :desc)
      end
      scope.limit(limit).pluck(:name).uniq
    end

    def suggest_genres(query, limit)
      scope = where.not(genres: [])
      genres = scope.pluck(:genres).flatten.tally.sort_by { |_genre, count| -count }.map(&:first)
      genres = genres.select { |g| g.downcase.include?(query.downcase) } if query.present?
      genres.first(limit)
    end

    def suggest_countries(query, limit)
      scope = where.not(country_of_origin: [])
      countries = scope.pluck(:country_of_origin).flatten.tally.sort_by { |_c, count| -count }.map(&:first)
      countries = countries.select { |c| c.downcase.include?(query.downcase) } if query.present?
      countries.first(limit)
    end

    def trigram_or_ilike(column, value)
      trigram = Arel::Nodes::InfixOperation.new('%', column, Arel::Nodes.build_quoted(value))
      trigram.or(column.matches("%#{sanitize_sql_like(value)}%"))
    end
  end
end
