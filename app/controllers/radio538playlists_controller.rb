class Radio538playlistsController < ApplicationController

  def index
    if params[:search_fullname].present?
      @radio538playlists = Radio538playlist.where("fullname ILIKE ?", "%#{params[:search_fullname]}%").paginate(page: params[:page]).per_page(10)
    else
      @radio538playlists = Radio538playlist.order(updated_at: :desc).paginate(page: params[:page]).per_page(10)
    end
    @uniq_tracks_day = Radio538playlist.uniq_tracks_day
    @uniq_tracks_week = Radio538playlist.uniq_tracks_week
    @uniq_tracks_month = Radio538playlist.uniq_tracks_month
    @uniq_tracks_year = Radio538playlist.uniq_tracks_year
  end

  def autocomplete
    @results = Radio538playlist.order(:fullname).where("fullname ILIKE ?", "%#{params[:term]}%").limit(10)
    render json: @results.map(&:fullname)
  end

  def sort_today
    @radio538playlists = Radio538playlist.sort_today.paginate(page: params[:page]).per_page(10)
  end

  def sort_week
    @radio538playlists = Radio538playlist.sort_week.paginate(page: params[:page]).per_page(10)
  end

  def sort_month
    @radio538playlists = Radio538playlist.sort_month.paginate(page: params[:page]).per_page(10)
  end

  def sort_year
    @radio538playlists = Radio538playlist.sort_year.paginate(page: params[:page]).per_page(10)
  end

  def sort_total
    @radio538playlists = Radio538playlist.sort_total.paginate(page: params[:page]).per_page(10)
  end

  def sort_created
    @radio538playlists = Radio538playlist.sort_created.paginate(page: params[:page]).per_page(10)
  end

  def sort_updated
    @radio538playlists = Radio538playlist.sort_updated.paginate(page: params[:page]).per_page(10)
  end


end
