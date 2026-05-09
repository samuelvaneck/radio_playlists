# frozen_string_literal: true

module SongSuggestionConcern
  extend ActiveSupport::Concern

  class_methods do
    def suggest(field:, query: nil, limit: 5)
      case field
      when 'artist' then suggest_artists(query, limit)
      when 'title' then suggest_titles(query, limit)
      when 'album' then suggest_albums(query, limit)
      when 'year' then suggest_years(limit)
      when 'theme' then suggest_themes(query, limit)
      when 'lyric_language' then suggest_lyric_languages(query, limit)
      else SongSearchConcern::SEARCH_FIELDS
      end
    end

    private

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

    def suggest_themes(query, limit)
      themes = Lyrics::ThemeTranslator::EN_TO_NL.keys
      themes = themes.select { |t| t.start_with?(query.downcase.strip) } if query.present?
      themes.first(limit)
    end

    def suggest_lyric_languages(query, limit)
      scope = Lyric.where.not(language: [nil, ''])
      scope = scope.where('language ILIKE ?', "#{ActiveRecord::Base.sanitize_sql_like(query.to_s.downcase.strip)}%") if query.present?
      scope.distinct.order(:language).limit(limit).pluck(:language)
    end
  end
end
