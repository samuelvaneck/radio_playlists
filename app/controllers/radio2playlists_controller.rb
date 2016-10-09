class Radio2playlistsController < ApplicationController

  def index
    if params[:search_fullname].present?
      @radio2playlists = Radio2playlist.where("fullname ILIKE ?", "%#{params[:search_fullname]}%").paginate(page: params[:page]).per_page(10)
    else
      @radio2playlists = Radio2playlist.order(updated_at: :desc).paginate(page: params[:page]).per_page(10)
    end
    @uniq_tracks_day = Radio2playlist.uniq_tracks_day
    @uniq_tracks_week = Radio2playlist.uniq_tracks_week
    @uniq_tracks_month = Radio2playlist.uniq_tracks_month
    @uniq_tracks_year = Radio2playlist.uniq_tracks_year
  end

  def autocomplete
    @results = Radio2playlist.order(:fullname).where("fullname ILIKE ?", "%#{params[:term]}%").limit(10)
    render json: @results.map(&:fullname)
  end

  def sort_today
    @radio2playlists = Radio2playlist.sort_today.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Radio2playlist.uniq_tracks_day
    @uniq_tracks_week = Radio2playlist.uniq_tracks_week
    @uniq_tracks_month = Radio2playlist.uniq_tracks_month
    @uniq_tracks_year = Radio2playlist.uniq_tracks_year
  end

  def sort_week
    @radio2playlists = Radio2playlist.sort_week.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Radio2playlist.uniq_tracks_day
    @uniq_tracks_week = Radio2playlist.uniq_tracks_week
    @uniq_tracks_month = Radio2playlist.uniq_tracks_month
    @uniq_tracks_year = Radio2playlist.uniq_tracks_year
  end

  def sort_month
    @radio2playlists = Radio2playlist.sort_month.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Radio2playlist.uniq_tracks_day
    @uniq_tracks_week = Radio2playlist.uniq_tracks_week
    @uniq_tracks_month = Radio2playlist.uniq_tracks_month
    @uniq_tracks_year = Radio2playlist.uniq_tracks_year
  end

  def sort_year
    @radio2playlists = Radio2playlist.sort_year.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Radio2playlist.uniq_tracks_day
    @uniq_tracks_week = Radio2playlist.uniq_tracks_week
    @uniq_tracks_month = Radio2playlist.uniq_tracks_month
    @uniq_tracks_year = Radio2playlist.uniq_tracks_year
  end

  def sort_total
    @radio2playlists = Radio2playlist.sort_total.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Radio2playlist.uniq_tracks_day
    @uniq_tracks_week = Radio2playlist.uniq_tracks_week
    @uniq_tracks_month = Radio2playlist.uniq_tracks_month
    @uniq_tracks_year = Radio2playlist.uniq_tracks_year
  end

  def sort_created
    @radio2playlists = Radio2playlist.sort_created.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Radio2playlist.uniq_tracks_day
    @uniq_tracks_week = Radio2playlist.uniq_tracks_week
    @uniq_tracks_month = Radio2playlist.uniq_tracks_month
    @uniq_tracks_year = Radio2playlist.uniq_tracks_year
  end

  def sort_updated
    @radio2playlists = Radio2playlist.sort_updated.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Radio2playlist.uniq_tracks_day
    @uniq_tracks_week = Radio2playlist.uniq_tracks_week
    @uniq_tracks_month = Radio2playlist.uniq_tracks_month
    @uniq_tracks_year = Radio2playlist.uniq_tracks_year
  end

end
