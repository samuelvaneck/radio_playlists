# frozen_string_literal: true

module Api
  module V1
    class SongsController < ApiController
      skip_before_action :authenticate_client!, only: :widget
      before_action :song, only: %i[show graph_data chart_positions time_analytics air_plays info music_profile widget]

      def index
        render json: SongSerializer.new(songs)
                       .serializable_hash
                       .merge(pagination_data(songs))
                       .to_json
      end

      def show
        render json: SongSerializer.new(song).serializable_hash.to_json
      end

      # GET /api/v1/songs/autocomplete
      #
      # Parameters:
      #   - q (required): Search query string
      #   - limit (optional, default: 10): Maximum number of results (max: 20)
      #
      # Response:
      # {
      #   "data": [
      #     { "id": "1", "type": "song", "attributes": { "id": 1, "title": "...", "artists": [...] } }
      #   ]
      # }
      def autocomplete
        results = Song.search_by_text(params[:q])
                    .select(:id, :title, :spotify_artwork_url)
                    .includes(:artists)
                    .limit(autocomplete_limit)

        render json: AutocompleteSongSerializer.new(results).serializable_hash.to_json
      end

      # GET /api/v1/songs/search
      #
      # Faceted search for songs. All filters are optional and combinable.
      #
      # Parameters:
      #   - q (optional): Free text search across title and artist
      #   - artist (optional): Filter by artist name (fuzzy match)
      #   - title (optional): Filter by song title (fuzzy match)
      #   - album (optional): Filter by album name (fuzzy match)
      #   - year_from (optional): Filter songs released in or after this year
      #   - year_to (optional): Filter songs released in or before this year
      #   - limit (optional, default: 10): Maximum number of results (max: 20)
      def search
        results = Song.includes(:artists).order(popularity: :desc)
        results = results.search_by_text(params[:q]) if params[:q].present?
        results = filter_by_artist(results)
        results = filter_by_title(results)
        results = filter_by_album(results)
        results = filter_by_year(results)
        results = results.limit(search_limit)

        render json: AutocompleteSongSerializer.new(results).serializable_hash.to_json
      end

      # GET /api/v1/songs/search_suggestions
      #
      # Returns autocomplete suggestions for a specific search field.
      #
      # Parameters:
      #   - field (required): Field to suggest values for (artist, title, album, year)
      #   - q (optional): Partial input to filter suggestions
      #   - limit (optional, default: 5): Maximum suggestions (max: 10)
      def search_suggestions
        suggestions = case params[:field]
                      when 'artist' then artist_suggestions
                      when 'title' then title_suggestions
                      when 'album' then album_suggestions
                      when 'year' then year_suggestions
                      else available_fields_response
                      end

        render json: { suggestions: suggestions, field: params[:field] }
      end

      def graph_data
        render json: song.graph_data(params[:period])
      end

      # GET /api/v1/songs/:id/chart_positions
      #
      # Parameters:
      #   - period (optional, default: 'month'): Time period for chart positions
      #     - 'week': last 7 days
      #     - 'month': last 30 days
      #     - 'year': last 365 days
      #     - 'all': all time
      #
      # Response:
      # [
      #   { "date": "2024-12-01", "position": 5, "counts": 42 },
      #   { "date": "2024-12-02", "position": 3, "counts": 58 },
      #   ...
      # ]
      def chart_positions
        render json: song.chart_positions_for_period(period_param)
      end

      # GET /api/v1/songs/:id/time_analytics
      #
      # Parameters:
      #   - radio_station_ids[] (optional): Filter by specific radio stations
      #   - weeks (optional, default: 4): Number of weeks for trend analysis
      #
      # Response:
      # {
      #   "peak_play_times": {
      #     "peak_hour": 8,
      #     "peak_day": 1,
      #     "peak_day_name": "Monday",
      #     "hourly_distribution": { "8": 5, "14": 3 },
      #     "daily_distribution": { "Monday": 10, "Tuesday": 8 }
      #   },
      #   "play_frequency_trend": {
      #     "trend": "rising",
      #     "trend_percentage": 25.5,
      #     "weekly_counts": { "2024-01-01": 5 },
      #     "first_period_avg": 4.0,
      #     "second_period_avg": 5.0
      #   },
      #   "lifecycle_stats": {
      #     "first_play": "2024-01-01T10:00:00Z",
      #     "last_play": "2024-12-01T15:00:00Z",
      #     "total_plays": 150,
      #     "days_since_first_play": 335,
      #     "days_since_last_play": 7,
      #     "days_active": 335,
      #     "unique_days_played": 120,
      #     "average_plays_per_day": 0.45,
      #     "play_consistency": 35.8
      #   }
      # }
      def time_analytics
        render json: {
          peak_play_times: song.peak_play_times_summary(radio_station_ids: radio_station_ids),
          play_frequency_trend: song.play_frequency_trend(weeks: weeks_param, radio_station_ids: radio_station_ids),
          lifecycle_stats: song.lifecycle_stats(radio_station_ids: radio_station_ids),
          lifecycle_phase: SongLifecycleDetector.new(song, radio_station_ids: radio_station_ids).detect
        }
      end

      # GET /api/v1/songs/:id/air_plays
      #
      # Parameters:
      #   - period (optional, default: 'day'): Time period for air plays
      #     Legacy: 'day', 'week', 'month', 'year', 'all'
      #     Granular: '1_day', '3_days', '2_weeks', '6_months', '1_year', etc.
      #   - radio_station_ids[] (optional): Filter by specific radio stations
      def air_plays
        render json: AirPlaySerializer.new(song_air_plays)
                       .serializable_hash
                       .merge(pagination_data(song_air_plays))
                       .to_json
      end

      # GET /api/v1/songs/:id/info
      #
      # Parameters:
      #   - language (optional, default: 'en'): Wikipedia language
      #     Supported: en, nl, de, fr, es, it, pt, pl, ru, ja, zh
      #
      # Example response:
      # {
      #   "info": {
      #     "summary": "...",
      #     "content": "...",
      #     "description": "2011 single by Adele",
      #     "url": "https://en.wikipedia.org/wiki/Rolling_in_the_Deep",
      #     "wikibase_item": "Q212764",
      #     "thumbnail": { "source": "...", "width": 320, "height": 213 },
      #     "original_image": { "source": "...", "width": 4272, "height": 2848 },
      #     "general_info": {
      #       "youtube_video_id": "rYEDA3JcQqw",
      #       "publication_date": "2010-11-29",
      #       "genres": ["soul", "pop"],
      #       "performers": ["Adele"],
      #       "record_labels": ["XL Recordings"]
      #     }
      #   }
      # }
      def info
        artist_name = song.artists.first&.name
        info_data = Wikipedia::SongFinder.new(language: language_param).get_info(song.title, artist_name)
        render json: { info: info_data }
      end

      # GET /api/v1/songs/:id/music_profile
      #
      # Returns the Spotify audio features for a song with attribute descriptions.
      #
      # Response:
      # {
      #   "data": {
      #     "id": "1",
      #     "type": "music_profile",
      #     "attributes": {
      #       "danceability": 0.65,
      #       "energy": 0.72,
      #       "speechiness": 0.08,
      #       "acousticness": 0.25,
      #       "instrumentalness": 0.02,
      #       "liveness": 0.12,
      #       "valence": 0.58,
      #       "tempo": 120.5
      #     }
      #   },
      #   "meta": {
      #     "attribute_descriptions": { ... }
      #   }
      # }
      def widget
        render json: song.widget_data
      end

      def music_profile
        hash = if song.music_profile.present?
                 MusicProfileSerializer.new(song.music_profile).serializable_hash
               else
                 { data: nil }
               end
        hash[:meta] = { attribute_descriptions: MusicProfile::ATTRIBUTE_DESCRIPTIONS }
        render json: hash.to_json
      end

      private

      def song_air_plays
        start_time, end_time = AirPlay.time_range_from_params(params, default_period: 'day')

        @song_air_plays ||= song.air_plays
                              .includes(:radio_station, song: :artists)
                              .played_between(start_time, end_time)
                              .played_on(radio_station_ids)
                              .order(broadcasted_at: :desc)
                              .paginate(page: params[:page], per_page: 24)
      end

      def songs
        @songs ||= Song.most_played(songs_params).paginate(page: params[:page], per_page: 24)
      end

      def songs_params
        {
          period: params[:period],
          start_time: params[:start_time],
          end_time: params[:end_time],
          radio_station_ids: params[:radio_station_ids],
          search_term: params[:search_term],
          music_profile: music_profile_params
        }
      end

      def music_profile_params
        params.permit(
          :danceability_min, :danceability_max,
          :energy_min, :energy_max,
          :speechiness_min, :speechiness_max,
          :acousticness_min, :acousticness_max,
          :instrumentalness_min, :instrumentalness_max,
          :liveness_min, :liveness_max,
          :valence_min, :valence_max,
          :tempo_min, :tempo_max
        ).to_h.presence
      end

      def song
        @song ||= if params[:id].to_i.to_s == params[:id]
                    Song.find(params[:id])
                  else
                    Song.find_by!(slug: params[:id])
                  end
      end

      def radio_station_ids
        return if params[:radio_station_ids].blank?

        Array(params[:radio_station_ids]).map(&:to_i)
      end

      def weeks_param
        params[:weeks].present? ? params[:weeks].to_i : 4
      end

      def period_param
        params[:period] || 'month'
      end

      def language_param
        params[:language] || 'en'
      end

      def autocomplete_limit
        [params.fetch(:limit, 10).to_i, 20].min
      end

      def search_limit
        [params.fetch(:limit, 10).to_i, 20].min
      end

      def suggestion_limit
        [params.fetch(:limit, 5).to_i, 10].min
      end

      def filter_by_artist(scope)
        return scope if params[:artist].blank?

        name_col = Artist.arel_table[:name]
        scope.joins(:artists).where(
          trigram_match(name_col, params[:artist]).or(name_col.matches("%#{Song.sanitize_sql_like(params[:artist])}%"))
        )
      end

      def filter_by_title(scope)
        return scope if params[:title].blank?

        title_col = Song.arel_table[:title]
        scope.where(
          trigram_match(title_col, params[:title]).or(title_col.matches("%#{Song.sanitize_sql_like(params[:title])}%"))
        )
      end

      def filter_by_album(scope)
        return scope if params[:album].blank?

        scope.where(Song.arel_table[:album_name].matches("%#{Song.sanitize_sql_like(params[:album])}%"))
      end

      def filter_by_year(scope)
        scope = scope.where(release_date: Date.new(params[:year_from].to_i)..) if params[:year_from].present?
        scope = scope.where(release_date: ..Date.new(params[:year_to].to_i).end_of_year) if params[:year_to].present?
        scope
      end

      def artist_suggestions
        query = params[:q]
        scope = Artist.order(spotify_popularity: :desc)
        if query.present?
          name_col = Artist.arel_table[:name]
          scope = scope.where(
            trigram_match(name_col, query).or(name_col.matches("%#{Artist.sanitize_sql_like(query)}%"))
          )
        end
        scope.limit(suggestion_limit).pluck(:name).uniq
      end

      def title_suggestions
        query = params[:q]
        scope = Song.order(popularity: :desc)
        if query.present?
          title_col = Song.arel_table[:title]
          scope = scope.where(
            trigram_match(title_col, query).or(title_col.matches("%#{Song.sanitize_sql_like(query)}%"))
          )
        end
        scope.limit(suggestion_limit).pluck(:title).uniq
      end

      def album_suggestions
        query = params[:q]
        scope = Song.where.not(album_name: [nil, ''])
        scope = scope.where(Song.arel_table[:album_name].matches("%#{Song.sanitize_sql_like(query)}%")) if query.present?
        scope.distinct.order(:album_name).limit(suggestion_limit).pluck(:album_name)
      end

      def year_suggestions
        year_col = Arel.sql('EXTRACT(YEAR FROM release_date)::integer')
        Song.where.not(release_date: nil)
          .select(year_col.as('year'))
          .distinct
          .order(year: :desc)
          .limit(suggestion_limit)
          .map(&:year)
      end

      def trigram_match(column, value)
        Arel::Nodes::InfixOperation.new('%', column, Arel::Nodes.build_quoted(value))
      end

      def available_fields_response
        %w[artist title album year_from year_to]
      end
    end
  end
end
