# frozen_string_literal: true

module SongSearchConcern
  extend ActiveSupport::Concern

  SEARCH_FIELDS = %w[artist title album year_from year_to theme lyric_language].freeze

  # Minimum pg_trgm similarity for a fuzzy match. The default `%` operator uses
  # pg_trgm.similarity_limit (0.3) which is too permissive for search; 0.5
  # roughly lets 1–2 character typos through while rejecting weakly-related
  # strings. Tightening the fuzzy arm only — the ILIKE arm still handles
  # substring queries like "love" → "True Love".
  SIMILARITY_THRESHOLD = 0.5

  def self.trigram_or_ilike(table, column, value)
    col = table.arel_table[column]
    similarity = Arel::Nodes::NamedFunction.new('similarity', [col, Arel::Nodes.build_quoted(value)])
    similarity_match = Arel::Nodes::GreaterThan.new(similarity, Arel::Nodes.build_quoted(SIMILARITY_THRESHOLD))
    similarity_match.or(col.matches("%#{ActiveRecord::Base.sanitize_sql_like(value)}%"))
  end

  def self.relevance_order(column, query)
    sanitized = ActiveRecord::Base.sanitize_sql_like(query)
    [
      Arel.sql(ActiveRecord::Base.sanitize_sql_array([
                                                       "CASE WHEN LOWER(#{column}) = LOWER(?) THEN 0 " \
                                                       "WHEN LOWER(#{column}) LIKE LOWER(?) THEN 1 ELSE 2 END",
                                                       query, "#{sanitized}%"
                                                     ])),
      Arel.sql(ActiveRecord::Base.sanitize_sql_array(["similarity(#{column}, ?) DESC", query]))
    ]
  end

  included do
    scope :filter_by_artist, lambda { |artist_name|
      return all if artist_name.blank?

      joins(:artists).where(SongSearchConcern.trigram_or_ilike(Artist, :name, artist_name))
    }
    scope :filter_by_title, lambda { |title|
      return all if title.blank?

      where(SongSearchConcern.trigram_or_ilike(self, :title, title))
    }
    scope :filter_by_album, lambda { |album|
      return all if album.blank?

      where(arel_table[:album_name].matches("%#{sanitize_sql_like(album)}%"))
    }
    scope :filter_by_theme, lambda { |theme|
      return all if theme.blank?

      normalized = theme.to_s.downcase.strip
      joins(:lyric).where('lyrics.themes @> ARRAY[?]::varchar[]', normalized)
    }
    scope :filter_by_lyric_language, lambda { |code|
      return all if code.blank?

      joins(:lyric).where(lyrics: { language: code.to_s.downcase.strip })
    }
    scope :filter_by_year_range, lambda { |year_from: nil, year_to: nil|
      scope = all
      scope = scope.where(release_date: Date.new(year_from.to_i)..) if year_from.present?
      scope = scope.where(release_date: ..Date.new(year_to.to_i).end_of_year) if year_to.present?
      scope
    }
    scope :sorted_by_air_plays, lambda {
      joins(:air_plays)
        .merge(AirPlay.confirmed)
        .select('songs.*, COUNT(air_plays.id) AS air_plays_count')
        .group('songs.id')
        .order(Arel.sql('air_plays_count DESC'))
    }
    scope :distinct_years, lambda { |limit|
      year_col = Arel.sql('EXTRACT(YEAR FROM release_date)::integer')
      where.not(release_date: nil)
        .select(year_col.as('year'))
        .distinct
        .order(year: :desc)
        .limit(limit)
    }
  end

  class_methods do
    def faceted_search(filters = {})
      scope = preload(:artists)
      scope = scope.search_by_text(filters[:q]) if filters[:q].present?
      scope = scope.filter_by_artist(filters[:artist])
                .filter_by_title(filters[:title])
                .filter_by_album(filters[:album])
                .filter_by_theme(filters[:theme])
                .filter_by_lyric_language(filters[:lyric_language])
                .filter_by_year_range(year_from: filters[:year_from], year_to: filters[:year_to])
                .limit(filters.fetch(:limit, 10))
      apply_faceted_sort(scope, filters[:sort_by])
    end

    private

    def apply_faceted_sort(scope, sort_by)
      case sort_by
      when 'most_played' then scope.sorted_by_air_plays
      when 'newest' then scope.order(Arel.sql('songs.release_date DESC NULLS LAST'))
      else scope.order(popularity: :desc)
      end
    end
  end
end
