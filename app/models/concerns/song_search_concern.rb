# frozen_string_literal: true

module SongSearchConcern
  extend ActiveSupport::Concern

  SEARCH_FIELDS = %w[artist title album year_from year_to].freeze

  def self.trigram_or_ilike(table, column, value)
    col = table.arel_table[column]
    trigram = Arel::Nodes::InfixOperation.new('%', col, Arel::Nodes.build_quoted(value))
    trigram.or(col.matches("%#{ActiveRecord::Base.sanitize_sql_like(value)}%"))
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

      name_col = Artist.arel_table[:name]
      trigram = Arel::Nodes::InfixOperation.new('%', name_col, Arel::Nodes.build_quoted(artist_name))
      joins(:artists).where(trigram.or(name_col.matches("%#{sanitize_sql_like(artist_name)}%")))
    }
    scope :filter_by_title, lambda { |title|
      return all if title.blank?

      title_col = arel_table[:title]
      trigram = Arel::Nodes::InfixOperation.new('%', title_col, Arel::Nodes.build_quoted(title))
      where(trigram.or(title_col.matches("%#{sanitize_sql_like(title)}%")))
    }
    scope :filter_by_album, lambda { |album|
      return all if album.blank?

      where(arel_table[:album_name].matches("%#{sanitize_sql_like(album)}%"))
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
      scope = includes(:artists)
      scope = scope.search_by_text(filters[:q]) if filters[:q].present?
      scope = scope.filter_by_artist(filters[:artist])
                .filter_by_title(filters[:title])
                .filter_by_album(filters[:album])
                .filter_by_year_range(year_from: filters[:year_from], year_to: filters[:year_to])
                .limit(filters.fetch(:limit, 10))
      apply_faceted_sort(scope, filters[:sort_by])
    end

    def suggest(field:, query: nil, limit: 5)
      case field
      when 'artist' then suggest_artists(query, limit)
      when 'title' then suggest_titles(query, limit)
      when 'album' then suggest_albums(query, limit)
      when 'year' then suggest_years(limit)
      else SEARCH_FIELDS
      end
    end

    private

    def apply_faceted_sort(scope, sort_by)
      case sort_by
      when 'most_played' then scope.sorted_by_air_plays
      when 'newest' then scope.order(Arel.sql('songs.release_date DESC NULLS LAST'))
      else scope.order(popularity: :desc)
      end
    end

    def suggest_artists(query, limit)
      scope = if query.present?
                Artist.where(SongSearchConcern.trigram_or_ilike(Artist, :name, query))
                  .order(*SongSearchConcern.relevance_order('artists.name', query), spotify_popularity: :desc)
              else
                Artist.order(spotify_popularity: :desc)
              end
      scope.limit(limit).pluck(:name).uniq
    end

    def suggest_titles(query, limit)
      scope = if query.present?
                where(SongSearchConcern.trigram_or_ilike(self, :title, query))
                  .order(*SongSearchConcern.relevance_order('songs.title', query), popularity: :desc)
              else
                order(popularity: :desc)
              end
      scope.limit(limit).pluck(:title).uniq
    end

    def suggest_albums(query, limit)
      scope = where.not(album_name: [nil, ''])
      scope = scope.where(arel_table[:album_name].matches("%#{sanitize_sql_like(query)}%")) if query.present?
      scope.distinct.order(:album_name).limit(limit).pluck(:album_name)
    end

    def suggest_years(limit)
      distinct_years(limit).map(&:year)
    end
  end
end
