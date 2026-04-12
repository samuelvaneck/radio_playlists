# frozen_string_literal: true

module SongSearchConcern
  extend ActiveSupport::Concern

  SEARCH_FIELDS = %w[artist title album year_from year_to].freeze

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
  end

  class_methods do
    def faceted_search(filters = {})
      scope = includes(:artists).order(popularity: :desc)
      scope = scope.search_by_text(filters[:q]) if filters[:q].present?
      scope.filter_by_artist(filters[:artist])
        .filter_by_title(filters[:title])
        .filter_by_album(filters[:album])
        .filter_by_year_range(year_from: filters[:year_from], year_to: filters[:year_to])
        .limit(filters.fetch(:limit, 10))
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

    def suggest_artists(query, limit)
      scope = Artist.order(spotify_popularity: :desc)
      if query.present?
        name_col = Artist.arel_table[:name]
        scope = scope.where(trigram_or_ilike(name_col, query))
      end
      scope.limit(limit).pluck(:name).uniq
    end

    def suggest_titles(query, limit)
      scope = order(popularity: :desc)
      if query.present?
        title_col = arel_table[:title]
        scope = scope.where(trigram_or_ilike(title_col, query))
      end
      scope.limit(limit).pluck(:title).uniq
    end

    def suggest_albums(query, limit)
      scope = where.not(album_name: [nil, ''])
      scope = scope.where(arel_table[:album_name].matches("%#{sanitize_sql_like(query)}%")) if query.present?
      scope.distinct.order(:album_name).limit(limit).pluck(:album_name)
    end

    def suggest_years(limit)
      year_col = Arel.sql('EXTRACT(YEAR FROM release_date)::integer')
      where.not(release_date: nil)
        .select(year_col.as('year'))
        .distinct
        .order(year: :desc)
        .limit(limit)
        .map(&:year)
    end

    def trigram_or_ilike(column, value)
      trigram = Arel::Nodes::InfixOperation.new('%', column, Arel::Nodes.build_quoted(value))
      trigram.or(column.matches("%#{sanitize_sql_like(value)}%"))
    end
  end
end
